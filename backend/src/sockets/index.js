import socketAuth from './socketAuth.js';
import registerClipboardHandlers from './clipboard.socket.js';
import registerTransferHandlers from './transfer.socket.js';
import logger from '../utils/logger.js';

/**
 * Wires application socket behavior onto the Socket.IO server:
 *   - JWT auth on every connection,
 *   - a private per-user room (`user:<id>`) for device-to-device relay,
 *   - clipboard sync handlers,
 *   - file-transfer signaling handlers (control plane only).
 *
 * Called once from the socket loader after the server is created.
 *
 * @param {import('socket.io').Server} io
 */
export default function registerSocketHandlers(io) {
  io.use(socketAuth);

  io.on('connection', (socket) => {
    const { userId, deviceId } = socket.data;

    // Join the user's private room so relays reach only their own devices.
    socket.join(`user:${userId}`);
    logger.debug(
      `[socket] user ${userId} connected (device ${deviceId ?? 'unknown'})`
    );

    registerClipboardHandlers(io, socket);
    registerTransferHandlers(io, socket);

    socket.on('disconnect', (reason) => {
      logger.debug(`[socket] user ${userId} disconnected (${reason})`);
    });
  });
}
