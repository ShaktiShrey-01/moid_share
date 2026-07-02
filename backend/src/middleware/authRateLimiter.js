import rateLimit from 'express-rate-limit';
import config from '../config/env.js';

/**
 * Stricter limiter for credential endpoints (login/register/forgot) to slow
 * brute-force and enumeration attempts. Keyed by IP.
 */
export const authRateLimiter = rateLimit({
  windowMs: config.rateLimit.windowMs,
  max: config.isProd ? 20 : 100,
  standardHeaders: 'draft-7',
  legacyHeaders: false,
  message: {
    success: false,
    error: {
      code: 'AUTH_RATE_LIMITED',
      message: 'Too many attempts. Please try again later.',
    },
  },
});
