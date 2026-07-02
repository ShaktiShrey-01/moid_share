import RefreshToken from '../models/refreshToken.model.js';

/** Data access for {@link RefreshToken} sessions. */
const refreshTokenRepository = {
  create(data) {
    return RefreshToken.create(data);
  },

  findActiveByHash(tokenHash) {
    return RefreshToken.findOne({ tokenHash, revokedAt: null }).exec();
  },

  /** Marks a single session revoked (optionally recording its successor). */
  revokeByHash(tokenHash, replacedByHash = null) {
    return RefreshToken.updateOne(
      { tokenHash },
      { $set: { revokedAt: new Date(), replacedByHash } }
    ).exec();
  },

  /** Revokes every active session for a user (global sign-out). */
  revokeAllForUser(userId) {
    return RefreshToken.updateMany(
      { user: userId, revokedAt: null },
      { $set: { revokedAt: new Date() } }
    ).exec();
  },
};

export default refreshTokenRepository;
