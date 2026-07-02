import loadMongoose from './mongoose.js';
import loadSocket from './socket.js';
import logger from '../utils/logger.js';

/**
 * Initializes external infrastructure in the correct order:
 *   1. database (must be reachable before serving),
 *   2. socket.io bound to the running HTTP server.
 *
 * The Express app itself is built separately in `app.js` (`createApp`) so it
 * can be unit-tested without a live database.
 *
 * @param {{ httpServer: import('http').Server }} deps
 * @returns {Promise<{ io: import('socket.io').Server }>}
 */
export default async function initInfrastructure({ httpServer }) {
  await loadMongoose();
  logger.debug('[loaders] mongoose ready');

  const io = loadSocket(httpServer);
  logger.debug('[loaders] socket ready');

  return { io };
}
