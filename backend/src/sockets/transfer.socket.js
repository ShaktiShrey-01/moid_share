import logger from '../utils/logger.js';

/**
 * File-transfer **signaling** over Socket.IO — control plane only.
 *
 * This relays the small JSON control messages that let two of a user's devices
 * negotiate a transfer (offer → accept/reject → complete/cancel). The actual
 * file bytes NEVER pass through the server: they travel over a direct
 * device-to-device channel (LAN socket today, native seam). We store nothing —
 * consistent with the clipboard relay and the project's "never store files"
 * rule.
 *
 * Every message is relayed only within the sender's private room
 * (`user:<id>`), so a user's devices can reach each other but no one else can.
 *
 * Contract (all payloads carry a `transferId` correlating the exchange):
 *   inbound  `transfer:offer`    { transferId, fileName, size, contentType?,
 *                                  toDeviceId?, sdp? }
 *   outbound `transfer:incoming` { ...offer, fromDeviceId, at }
 *
 *   inbound  `transfer:accept`   { transferId, toDeviceId?, sdp? }
 *   outbound `transfer:accepted` { transferId, fromDeviceId, sdp?, at }
 *
 *   inbound  `transfer:reject`   { transferId, reason? }
 *   outbound `transfer:rejected` { transferId, fromDeviceId, reason?, at }
 *
 *   inbound  `transfer:cancel`   { transferId, reason? }
 *   outbound `transfer:cancelled`{ transferId, fromDeviceId, reason?, at }
 *
 *   inbound  `transfer:complete` { transferId, ok }
 *   outbound `transfer:completed`{ transferId, fromDeviceId, ok, at }
 *
 * @param {import('socket.io').Server} io
 * @param {import('socket.io').Socket} socket
 */
export default function registerTransferHandlers(io, socket) {
  const { userId, deviceId } = socket.data;

  // Control messages are tiny; guard against anything that isn't signaling.
  const MAX_CONTROL_BYTES = 16 * 1024; // 16 KB (sdp/metadata only, no bytes)

  /**
   * Relays one control event to the user's other devices, echoing back an ack.
   * Shapes the outbound payload uniformly (adds `fromDeviceId` + `at`).
   *
   * @param {string} inbound  event name received from this device
   * @param {string} outbound event name emitted to the other devices
   * @param {(p: object) => object} shape maps inbound payload to outbound body
   */
  const relay = (inbound, outbound, shape) => {
    socket.on(inbound, (payload, ack) => {
      const transferId = payload?.transferId;
      if (typeof transferId !== 'string' || transferId.length === 0) {
        if (typeof ack === 'function') ack({ ok: false, error: 'INVALID_PAYLOAD' });
        return;
      }
      if (Buffer.byteLength(JSON.stringify(payload ?? {}), 'utf8') > MAX_CONTROL_BYTES) {
        if (typeof ack === 'function') ack({ ok: false, error: 'TOO_LARGE' });
        return;
      }

      const message = {
        ...shape(payload),
        transferId,
        fromDeviceId: deviceId,
        at: new Date().toISOString(),
      };

      socket.to(`user:${userId}`).emit(outbound, message);

      // Metadata only — never log file names' contents beyond basic tracing.
      logger.debug(
        `[transfer] ${inbound} -> ${outbound} (${transferId}) for user ${userId} ` +
          `from device ${deviceId ?? 'unknown'}`
      );

      if (typeof ack === 'function') ack({ ok: true });
    });
  };

  relay('transfer:offer', 'transfer:incoming', (p) => ({
    fileName: typeof p.fileName === 'string' ? p.fileName : 'file',
    size: Number.isFinite(p.size) ? p.size : 0,
    contentType: p.contentType ?? 'application/octet-stream',
    toDeviceId: p.toDeviceId ?? null,
    sdp: p.sdp ?? null,
  }));

  relay('transfer:accept', 'transfer:accepted', (p) => ({
    toDeviceId: p.toDeviceId ?? null,
    sdp: p.sdp ?? null,
  }));

  relay('transfer:reject', 'transfer:rejected', (p) => ({
    reason: p.reason ?? null,
  }));

  relay('transfer:cancel', 'transfer:cancelled', (p) => ({
    reason: p.reason ?? null,
  }));

  relay('transfer:complete', 'transfer:completed', (p) => ({
    ok: p.ok === true,
  }));
}
