import express from 'express';
import helmet from 'helmet';
import cors from 'cors';
import compression from 'compression';
import morgan from 'morgan';
import { randomUUID } from 'node:crypto';

import config from '../config/env.js';
import logger from '../utils/logger.js';
import { apiRateLimiter } from '../middleware/rateLimiter.js';
import notFound from '../middleware/notFound.js';
import errorHandler from '../middleware/errorHandler.js';
import registerRoutes from '../routes/index.js';

/**
 * Builds and configures the Express application.
 *
 * Middleware order is deliberate:
 *   security → cors → parsers → compression → request-id → http logs →
 *   rate limit → routes → 404 → error handler (always last).
 *
 * @param {express.Application} [app]
 * @returns {express.Application}
 */
export default function loadExpress(app = express()) {
  app.set('trust proxy', config.server.trustProxy);
  app.disable('x-powered-by');

  // -- Security headers --------------------------------------------------
  app.use(helmet());

  // -- CORS --------------------------------------------------------------
  const { corsOrigins } = config.security;
  app.use(
    cors({
      origin:
        corsOrigins.includes('*') || corsOrigins.length === 0
          ? true
          : corsOrigins,
      credentials: true,
    })
  );

  // -- Body parsers (bounded to mitigate abuse) --------------------------
  app.use(express.json({ limit: '1mb' }));
  app.use(express.urlencoded({ extended: true, limit: '1mb' }));

  // -- Compression -------------------------------------------------------
  app.use(compression());

  // -- Request id (correlation across logs) ------------------------------
  app.use((req, res, next) => {
    req.id = req.headers['x-request-id'] ?? randomUUID();
    res.setHeader('X-Request-Id', req.id);
    next();
  });

  // -- HTTP access logs (piped through our logger) -----------------------
  app.use(
    morgan(config.logging.httpFormat, {
      stream: { write: (msg) => logger.info(msg.trim()) },
    })
  );

  // -- Rate limiting (applied to the API surface) ------------------------
  app.use(config.server.apiPrefix, apiRateLimiter);

  // -- Feature routes ----------------------------------------------------
  registerRoutes(app);

  // -- 404 + centralized error handling (must be last) -------------------
  app.use(notFound);
  app.use(errorHandler);

  return app;
}
