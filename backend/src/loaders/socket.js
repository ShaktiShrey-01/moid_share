import { Server } from 'socket.io';
import config from '../config/env.js';
import logger from '../utils/logger.js';
import registerSocketHandlers from '../sockets/index.js';

/**
 * Attaches a Socket.IO server to the given HTTP server and wires the
 * application's authenticated socket handlers (see `src/sockets`).
 *
 * IMPORTANT: realtime is used only for *signaling / relay*. Clipboard content
 * is relayed between a user's own devices in memory but is NEVER persisted
 * server-side; file bytes are never relayed here at all.
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
    // Cap payloads to protect the relay from oversized messages.
    maxHttpBufferSize: 512 * 1024,
  });

  registerSocketHandlers(io);

  logger.info('[socket] Socket.IO initialized (authenticated)');
  return io;
}
