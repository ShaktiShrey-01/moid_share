import { StatusCodes } from 'http-status-codes';

/**
 * Operational error with an HTTP status.
 *
 * Thrown by services/controllers and handled centrally by the error
 * middleware. `isOperational` distinguishes expected errors (bad input, not
 * found) from programmer bugs, so we can decide what to expose to clients.
 */
export default class ApiError extends Error {
  /**
   * @param {number} statusCode HTTP status code.
   * @param {string} message Client-safe message.
   * @param {object} [options]
   * @param {string} [options.code] Stable machine code (e.g. 'AUTH_INVALID').
   * @param {Array}  [options.details] Field-level validation details.
   * @param {boolean}[options.isOperational=true]
   */
  constructor(statusCode, message, { code, details, isOperational = true } = {}) {
    super(message);
    this.name = 'ApiError';
    this.statusCode = statusCode;
    this.code = code;
    this.details = details;
    this.isOperational = isOperational;
    Error.captureStackTrace?.(this, this.constructor);
  }

  static badRequest(message = 'Bad request', opts) {
    return new ApiError(StatusCodes.BAD_REQUEST, message, opts);
  }

  static unauthorized(message = 'Unauthorized', opts) {
    return new ApiError(StatusCodes.UNAUTHORIZED, message, opts);
  }

  static forbidden(message = 'Forbidden', opts) {
    return new ApiError(StatusCodes.FORBIDDEN, message, opts);
  }

  static notFound(message = 'Resource not found', opts) {
    return new ApiError(StatusCodes.NOT_FOUND, message, opts);
  }

  static conflict(message = 'Conflict', opts) {
    return new ApiError(StatusCodes.CONFLICT, message, opts);
  }

  static unprocessable(message = 'Validation failed', opts) {
    return new ApiError(StatusCodes.UNPROCESSABLE_ENTITY, message, opts);
  }

  static internal(message = 'Internal server error', opts) {
    return new ApiError(StatusCodes.INTERNAL_SERVER_ERROR, message, {
      ...opts,
      isOperational: false,
    });
  }
}
