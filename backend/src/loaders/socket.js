import { Server } from 'socket.io';
import config from '../config/env.js';
import logger from '../utils/logger.js';

/**
 * Attaches a Socket.IO server to the given HTTP server.
 *
 * Foundation scope: server is created, CORS-scoped, and a connection log is
 * wired. The authentication handshake and device/clipboard signaling
 * namespaces are added in their respective feature steps — this is the seam.
 *
 * IMPORTANT: realtime is used only for *signaling* (presence, pairing,
 * clipboard change notifications). File bytes and clipboard contents are never
 * relayed or stored server-side.
 *
 * @param {import('http').Server} httpServer
 * @returns {Server}
 */
export default function loadSocket(httpServer) {
  const { corsOrigins } = config.security;
  const io = new Server(httpServer, {
    cors: {
      origin:
        corsOrigins.includes('*') || corsOrigins.length === 0
          ? true
          : corsOrigins,
      credentials: true,
    },
    // Clients ping/pong to detect dead connections quickly.
    pingTimeout: 20_000,
    pingInterval: 25_000,
  });

  io.on('connection', (socket) => {
    logger.debug(`[socket] connected: ${socket.id}`);
    socket.on('disconnect', (reason) =>
      logger.debug(`[socket] disconnected: ${socket.id} (${reason})`)
    );
  });

  logger.info('[socket] Socket.IO initialized');
  return io;
}
