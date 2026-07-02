import tokenService from '../services/token.service.js';
import ApiError from '../utils/ApiError.js';

/**
 * Protects routes by requiring a valid Bearer access token.
 *
 * On success attaches `req.auth = { userId }`. Token/format errors are thrown as
 * ApiError and normalized by the error middleware (401). We intentionally do
 * NOT hit the DB here — that stays O(1) and stateless; handlers load the user
 * if they need the full document.
 */
export default function authenticate(req, _res, next) {
  const header = req.headers.authorization ?? '';
  const [scheme, token] = header.split(' ');

  if (scheme !== 'Bearer' || !token) {
    return next(
      ApiError.unauthorized('Missing or malformed Authorization header', {
        code: 'AUTH_HEADER_MISSING',
      })
    );
  }

  try {
    const payload = tokenService.verifyAccessToken(token);
    req.auth = { userId: payload.sub };
    return next();
  } catch (err) {
    // TokenExpiredError / JsonWebTokenError → mapped to 401 by errorHandler.
    return next(err);
  }
}
