import logger from '../utils/logger.js';

/**
 * Clipboard sync over Socket.IO — **relay only, zero persistence**.
 *
 * When a device emits `clipboard:sync`, we forward it to that user's OTHER
 * devices as `clipboard:incoming`. The payload is passed through in memory and
 * never written to MongoDB or logs (we log only metadata: length + device).
 *
 * Contract:
 *   inbound  `clipboard:sync`     { content: string, contentType?: string }
 *   outbound `clipboard:incoming` { content, contentType, fromDeviceId, at }
 *
 * @param {import('socket.io').Server} io
 * @param {import('socket.io').Socket} socket
 */
export default function registerClipboardHandlers(io, socket) {
  const { userId, deviceId } = socket.data;

  // Reject absurd payloads early (clipboard sync is for text, not blobs).
  const MAX_CONTENT_BYTES = 256 * 1024; // 256 KB

  socket.on('clipboard:sync', (payload, ack) => {
    const content = payload?.content;
    if (typeof content !== 'string' || content.length === 0) {
      if (typeof ack === 'function') {
        ack({ ok: false, error: 'INVALID_PAYLOAD' });
      }
      return;
    }
    if (Buffer.byteLength(content, 'utf8') > MAX_CONTENT_BYTES) {
      if (typeof ack === 'function') ack({ ok: false, error: 'TOO_LARGE' });
      return;
    }

    const message = {
      content,
      contentType: payload?.contentType ?? 'text/plain',
      fromDeviceId: deviceId,
      at: new Date().toISOString(),
    };

    // Relay to the user's other devices only (room excludes the sender).
    socket.to(`user:${userId}`).emit('clipboard:incoming', message);

    // Metadata only — never log clipboard content.
    logger.debug(
      `[clipboard] relayed ${message.content.length} chars for user ${userId} ` +
        `from device ${deviceId ?? 'unknown'}`
    );

    if (typeof ack === 'function') ack({ ok: true });
  });
}
