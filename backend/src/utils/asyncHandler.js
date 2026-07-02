/**
 * Wraps an async route handler so rejected promises are forwarded to Express's
 * error middleware instead of crashing the process. Removes the need for
 * try/catch in every controller.
 *
 * @param {Function} fn async (req, res, next) => {...}
 */
export default function asyncHandler(fn) {
  return (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);
}
