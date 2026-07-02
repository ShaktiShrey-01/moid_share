import crypto from 'node:crypto';

import userRepository from '../repositories/user.repository.js';
import refreshTokenRepository from '../repositories/refreshToken.repository.js';
import passwordService from './password.service.js';
import tokenService from './token.service.js';
import googleService from './google.service.js';
import mailerService from './mailer.service.js';
import ApiError from '../utils/ApiError.js';

/**
 * Authentication business logic.
 *
 * Depends only on repositories and sibling services (no Express/HTTP concerns),
 * so it is unit-testable and reusable (e.g. from a socket handshake later).
 */
const PASSWORD_RESET_TTL_MS = 60 * 60 * 1000; // 1 hour

const authService = {
  /** Registers a new local account and starts a session. */
  async register({ name, email, password, device }) {
    const existing = await userRepository.findByEmail(email);
    if (existing) {
      throw ApiError.conflict('Email already registered', {
        code: 'EMAIL_TAKEN',
      });
    }

    const passwordHash = await passwordService.hash(password);
    const user = await userRepository.create({
      name,
      email,
      passwordHash,
      providers: ['local'],
    });

    const tokens = await this._issueTokens(user, device);
    return { user: user.toPublicJSON(), tokens };
  },

  /** Verifies credentials and starts a session. */
  async login({ email, password, device }) {
    const user = await userRepository.findByEmailWithSecret(email);
    // Constant-ish response: same error whether user missing or bad password.
    const ok = user && (await passwordService.compare(password, user.passwordHash));
    if (!ok) {
      throw ApiError.unauthorized('Invalid email or password', {
        code: 'INVALID_CREDENTIALS',
      });
    }

    const tokens = await this._issueTokens(user, device);
    return { user: user.toPublicJSON(), tokens };
  },

  /** Rotates a refresh token: validates, revokes old, issues a fresh pair. */
  async refresh({ refreshToken, device }) {
    if (!refreshToken) {
      throw ApiError.unauthorized('Refresh token required', {
        code: 'REFRESH_REQUIRED',
      });
    }
    const tokenHash = tokenService.hashToken(refreshToken);
    const session = await refreshTokenRepository.findActiveByHash(tokenHash);

    if (!session || !session.isActive) {
      throw ApiError.unauthorized('Invalid or expired session', {
        code: 'REFRESH_INVALID',
      });
    }

    const user = await userRepository.findById(session.user);
    if (!user) {
      throw ApiError.unauthorized('Account no longer exists', {
        code: 'USER_GONE',
      });
    }

    const tokens = await this._issueTokens(user, device);
    // Revoke the old token, recording the successor for audit.
    await refreshTokenRepository.revokeByHash(
      tokenHash,
      tokenService.hashToken(tokens.refreshToken)
    );

    return { user: user.toPublicJSON(), tokens };
  },

  /** Revokes a single session (best-effort; idempotent). */
  async logout({ refreshToken }) {
    if (!refreshToken) return;
    await refreshTokenRepository.revokeByHash(
      tokenService.hashToken(refreshToken)
    );
  },

  /**
   * Starts a password reset. Always resolves without revealing whether the
   * email exists (prevents account enumeration).
   */
  async forgotPassword({ email }) {
    const user = await userRepository.findByEmail(email);
    if (!user) return;

    const rawToken = crypto.randomBytes(32).toString('hex');
    user.passwordResetTokenHash = tokenService.hashToken(rawToken);
    user.passwordResetExpiresAt = new Date(Date.now() + PASSWORD_RESET_TTL_MS);
    await user.save();

    await mailerService.sendPasswordReset({ to: user.email, resetToken: rawToken });
  },

  /** Completes a password reset and revokes all existing sessions. */
  async resetPassword({ token, password }) {
    const tokenHash = tokenService.hashToken(token);
    const user = await userRepository.findByActiveResetTokenHash(tokenHash);
    if (!user) {
      throw ApiError.badRequest('Invalid or expired reset token', {
        code: 'RESET_INVALID',
      });
    }

    user.passwordHash = await passwordService.hash(password);
    user.passwordResetTokenHash = null;
    user.passwordResetExpiresAt = null;
    if (!user.providers.includes('local')) user.providers.push('local');
    await user.save();

    // Security: invalidate every session after a password change.
    await refreshTokenRepository.revokeAllForUser(user._id);
  },

  /** Signs in (or provisions) a user from a verified Google ID token. */
  async googleSignIn({ idToken, device }) {
    const profile = await googleService.verifyIdToken(idToken);

    let user = await userRepository.findByGoogleId(profile.googleId);
    if (!user) {
      // Link Google to an existing local account with the same email, else create.
      user = await userRepository.findByEmail(profile.email);
      if (user) {
        user.googleId = profile.googleId;
        if (!user.providers.includes('google')) user.providers.push('google');
        user.avatarUrl ??= profile.avatarUrl;
        user.emailVerified = user.emailVerified || profile.emailVerified;
        await user.save();
      } else {
        user = await userRepository.create({
          name: profile.name,
          email: profile.email,
          googleId: profile.googleId,
          avatarUrl: profile.avatarUrl,
          providers: ['google'],
          emailVerified: profile.emailVerified,
        });
      }
    }

    const tokens = await this._issueTokens(user, device);
    return { user: user.toPublicJSON(), tokens };
  },

  /** Returns the public profile for an authenticated user id. */
  async getMe(userId) {
    const user = await userRepository.findById(userId);
    if (!user) {
      throw ApiError.notFound('User not found', { code: 'USER_NOT_FOUND' });
    }
    return user.toPublicJSON();
  },

  /**
   * Issues an access JWT + a persisted opaque refresh token for a user/device.
   * @private
   */
  async _issueTokens(user, device) {
    const accessToken = tokenService.signAccessToken(user._id.toString());
    const refreshToken = tokenService.generateRefreshToken();

    await refreshTokenRepository.create({
      user: user._id,
      tokenHash: tokenService.hashToken(refreshToken),
      device: {
        id: device?.id ?? null,
        name: device?.name ?? null,
        platform: device?.platform ?? null,
      },
      expiresAt: tokenService.refreshTokenExpiry(),
    });

    return {
      tokenType: 'Bearer',
      accessToken,
      refreshToken,
      accessExpiresIn: tokenService.accessTokenTtlSeconds(),
    };
  },
};

export default authService;
