import { OAuth2Client } from 'google-auth-library';
import config from '../config/env.js';
import ApiError from '../utils/ApiError.js';

/**
 * Verifies Google ID tokens (from the client's Google Sign-In flow) and returns
 * the trusted profile. Verification is done against Google's public keys and
 * our OAuth client id (audience), so a forged token is rejected.
 */
const client = new OAuth2Client(config.google.clientId);

const googleService = {
  get isConfigured() {
    return Boolean(config.google.clientId);
  },

  /**
   * @param {string} idToken
   * @returns {Promise<{ googleId:string, email:string, name:string, avatarUrl:string|null, emailVerified:boolean }>}
   */
  async verifyIdToken(idToken) {
    if (!this.isConfigured) {
      throw new ApiError(501, 'Google sign-in is not configured', {
        code: 'GOOGLE_NOT_CONFIGURED',
      });
    }
    let ticket;
    try {
      ticket = await client.verifyIdToken({
        idToken,
        audience: config.google.clientId,
      });
    } catch {
      throw ApiError.unauthorized('Invalid Google token', {
        code: 'GOOGLE_TOKEN_INVALID',
      });
    }

    const payload = ticket.getPayload();
    if (!payload?.email) {
      throw ApiError.unauthorized('Google token missing email', {
        code: 'GOOGLE_TOKEN_INVALID',
      });
    }

    return {
      googleId: payload.sub,
      email: payload.email,
      name: payload.name ?? payload.email.split('@')[0],
      avatarUrl: payload.picture ?? null,
      emailVerified: Boolean(payload.email_verified),
    };
  },
};

export default googleService;
