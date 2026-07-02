import http from 'node:http';

import config from './config/env.js';
import logger from './utils/logger.js';
import { createApp } from './app.js';
import initInfrastructure from './loaders/index.js';
import { disconnectMongoose } from './loaders/mongoose.js';

/**
 * Process entry point and lifecycle owner.
 *
 * Responsibilities:
 *   - build the app and HTTP server,
 *   - initialize infrastructure (DB, sockets),
 *   - start listening,
 *   - install signal + fatal-error handlers for graceful shutdown.
 */
async function start() {
  const app = createApp();
  const httpServer = http.createServer(app);

  const { io } = await initInfrastructure({ httpServer });

  httpServer.listen(config.server.port, () => {
    logger.info(
      `[server] Moid-Share API listening on :${config.server.port} ` +
        `(${config.env}) at ${config.server.apiPrefix}`
    );
  });

  registerLifecycleHandlers({ httpServer, io });
}

/**
 * Wires graceful shutdown and last-resort fatal handlers. Shutdown drains the
 * HTTP server, closes sockets, then the DB — bounded by a timeout so a stuck
 * connection can't hang the process forever.
 */
function registerLifecycleHandlers({ httpServer, io }) {
  let shuttingDown = false;

  const shutdown = async (signal) => {
    if (shuttingDown) return;
    shuttingDown = true;
    logger.info(`[server] ${signal} received — shutting down gracefully`);

    const forceExit = setTimeout(() => {
      logger.error('[server] forced shutdown after timeout');
      process.exit(1);
    }, 10_000);
    forceExit.unref();

    try {
      await io?.close();
      await new Promise((resolve, reject) =>
        httpServer.close((err) => (err ? reject(err) : resolve()))
      );
      await disconnectMongoose();
      clearTimeout(forceExit);
      logger.info('[server] shutdown complete');
      process.exit(0);
    } catch (err) {
      logger.error('[server] error during shutdown', err);
      process.exit(1);
    }
  };

  ['SIGINT', 'SIGTERM'].forEach((sig) =>
    process.on(sig, () => shutdown(sig))
  );

  // Fail fast on programmer errors; a process manager should restart us.
  process.on('unhandledRejection', (reason) => {
    logger.error('[server] unhandledRejection', reason);
    shutdown('unhandledRejection');
  });
  process.on('uncaughtException', (err) => {
    logger.error('[server] uncaughtException', err);
    shutdown('uncaughtException');
  });
}

start().catch((err) => {
  logger.error('[server] failed to start', err);
  process.exit(1);
});
