import rateLimit from 'express-rate-limit';
import config from '../config/env.js';

/**
 * Global API rate limiter. A stricter limiter for auth routes is added in the
 * auth feature. Uses standard `RateLimit-*` headers.
 */
export const apiRateLimiter = rateLimit({
  windowMs: config.rateLimit.windowMs,
  max: config.rateLimit.max,
  standardHeaders: 'draft-7',
  legacyHeaders: false,
  message: {
    success: false,
    error: { code: 'RATE_LIMITED', message: 'Too many requests, slow down.' },
  },
});
