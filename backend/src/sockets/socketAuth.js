import tokenService from '../services/token.service.js';

/**
 * Socket.IO authentication middleware.
 *
 * The client presents its access JWT during the handshake (either
 * `auth.token` or the `Authorization: Bearer` header). We verify it with the
 * same {@link tokenService} used by the REST layer and attach the user id to
 * the socket. Unauthenticated sockets are rejected before any event flows.
 *
 * @param {import('socket.io').Socket} socket
 * @param {(err?: Error) => void} next
 */
export default function socketAuth(socket, next) {
  try {
    const fromAuth = socket.handshake.auth?.token;
    const header = socket.handshake.headers?.authorization ?? '';
    const fromHeader = header.startsWith('Bearer ') ? header.slice(7) : null;
    const token = fromAuth || fromHeader;

    if (!token) {
      return next(new Error('UNAUTHORIZED'));
    }

    const payload = tokenService.verifyAccessToken(token);
    // Attach identity + optional device id (sent by the client handshake).
    socket.data.userId = payload.sub;
    socket.data.deviceId = socket.handshake.auth?.deviceId ?? null;
    return next();
  } catch {
    return next(new Error('UNAUTHORIZED'));
  }
}
