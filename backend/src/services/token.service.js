import crypto from 'node:crypto';
import jwt from 'jsonwebtoken';
import config from '../config/env.js';

/**
 * Token operations:
 *   - short-lived **access** JWTs (stateless, verified on every request), and
 *   - opaque **refresh** tokens (random, stored hashed for revocation/rotation).
 *
 * Refresh tokens are intentionally NOT JWTs so sessions can be revoked
 * server-side and rotated on each use.
 */
const tokenService = {
  /** Signs an access JWT for a user id. */
  signAccessToken(userId) {
    return jwt.sign({ sub: userId, type: 'access' }, config.jwt.accessSecret, {
      expiresIn: config.jwt.accessExpiresIn,
    });
  },

  /** Verifies an access JWT, returning its payload or throwing. */
  verifyAccessToken(token) {
    const payload = jwt.verify(token, config.jwt.accessSecret);
    if (payload.type !== 'access') {
      throw new jwt.JsonWebTokenError('Wrong token type');
    }
    return payload;
  },

  /** Generates a cryptographically-random opaque refresh token (raw). */
  generateRefreshToken() {
    return crypto.randomBytes(48).toString('hex');
  },

  /** SHA-256 hex of an opaque token — what we persist/compare. */
  hashToken(raw) {
    return crypto.createHash('sha256').update(raw).digest('hex');
  },

  /** Refresh token absolute expiry as a Date, derived from config. */
  refreshTokenExpiry() {
    return new Date(Date.now() + parseDurationMs(config.jwt.refreshExpiresIn));
  },

  /** Access-token lifetime in seconds (sent to clients for scheduling). */
  accessTokenTtlSeconds() {
    return Math.floor(parseDurationMs(config.jwt.accessExpiresIn) / 1000);
  },
};

/**
 * Parses simple duration strings like '15m', '30d', '12h', '45s', or a raw
 * number of seconds, into milliseconds.
 */
export function parseDurationMs(value) {
  if (typeof value === 'number') return value * 1000;
  const match = /^(\d+)\s*([smhd])?$/.exec(String(value).trim());
  if (!match) throw new Error(`Invalid duration: ${value}`);
  const amount = Number(match[1]);
  const unit = match[2] ?? 's';
  const unitMs = { s: 1000, m: 60_000, h: 3_600_000, d: 86_400_000 };
  return amount * unitMs[unit];
}

export default tokenService;
