import ApiError from '../utils/ApiError.js';

/** Catches unmatched routes and forwards a 404 to the error handler. */
export default function notFound(req, _res, next) {
  next(ApiError.notFound(`Route not found: ${req.method} ${req.originalUrl}`, {
    code: 'ROUTE_NOT_FOUND',
  }));
}
