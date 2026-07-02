import { StatusCodes, getReasonPhrase } from 'http-status-codes';
import mongoose from 'mongoose';
import ApiError from '../utils/ApiError.js';
import logger from '../utils/logger.js';
import config from '../config/env.js';

/**
 * Converts known non-ApiError errors (Mongoose, JWT) into ApiError so the
 * response shape stays uniform. Unknown errors become a 500.
 */
function normalize(err) {
  if (err instanceof ApiError) return err;

  // Mongoose schema validation.
  if (err instanceof mongoose.Error.ValidationError) {
    const details = Object.values(err.errors).map((e) => ({
      field: e.path,
      message: e.message,
    }));
    return ApiError.unprocessable('Validation failed', {
      code: 'VALIDATION_ERROR',
      details,
    });
  }

  // Malformed ObjectId etc.
  if (err instanceof mongoose.Error.CastError) {
    return ApiError.badRequest(`Invalid value for "${err.path}"`, {
      code: 'CAST_ERROR',
    });
  }

  // Duplicate key (unique index) — e.g. email already registered.
  if (err?.code === 11000) {
    const field = Object.keys(err.keyValue ?? {})[0] ?? 'field';
    return ApiError.conflict(`${field} already exists`, {
      code: 'DUPLICATE_KEY',
      details: [{ field, message: 'must be unique' }],
    });
  }

  // JWT errors.
  if (err?.name === 'TokenExpiredError') {
    return ApiError.unauthorized('Token expired', { code: 'TOKEN_EXPIRED' });
  }
  if (err?.name === 'JsonWebTokenError') {
    return ApiError.unauthorized('Invalid token', { code: 'TOKEN_INVALID' });
  }

  // Fallback: treat as internal, non-operational.
  return ApiError.internal(err?.message ?? 'Internal server error');
}

/**
 * Terminal Express error middleware (must have 4 args).
 * Emits the standard error envelope:
 *   { success:false, error:{ code, message, details? } }
 */
// eslint-disable-next-line no-unused-vars
export default function errorHandler(err, req, res, next) {
  const apiError = normalize(err);
  const { statusCode } = apiError;

  // Log 5xx as errors (with stack), 4xx as warnings.
  if (statusCode >= StatusCodes.INTERNAL_SERVER_ERROR) {
    logger.error(`${req.method} ${req.originalUrl} -> ${statusCode}`, err);
  } else {
    logger.warn(`${req.method} ${req.originalUrl} -> ${statusCode} ${apiError.message}`);
  }

  const body = {
    success: false,
    error: {
      code: apiError.code ?? getReasonPhrase(statusCode).replace(/\s+/g, '_').toUpperCase(),
      message:
        apiError.isOperational || !config.isProd
          ? apiError.message
          : 'Something went wrong. Please try again.',
    },
  };
  if (apiError.details) body.error.details = apiError.details;
  // Expose stack only outside production for debugging.
  if (!config.isProd && statusCode >= 500) body.error.stack = err?.stack;

  res.status(statusCode).json(body);
}
