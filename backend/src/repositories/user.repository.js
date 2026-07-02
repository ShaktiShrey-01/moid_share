import User from '../models/user.model.js';

/**
 * Data access for {@link User}. Keeps Mongoose query details out of services so
 * business logic stays persistence-agnostic and mockable in tests.
 */
const userRepository = {
  /** @returns {Promise<import('mongoose').HydratedDocument|null>} */
  findById(id) {
    return User.findById(id).exec();
  },

  findByEmail(email) {
    return User.findOne({ email: email.toLowerCase() }).exec();
  },

  /** Includes the normally-hidden passwordHash for credential checks. */
  findByEmailWithSecret(email) {
    return User.findOne({ email: email.toLowerCase() })
      .select('+passwordHash')
      .exec();
  },

  findByGoogleId(googleId) {
    return User.findOne({ googleId }).exec();
  },

  /** Looks up by reset token hash, checking expiry in the query. */
  findByActiveResetTokenHash(tokenHash) {
    return User.findOne({
      passwordResetTokenHash: tokenHash,
      passwordResetExpiresAt: { $gt: new Date() },
    })
      .select('+passwordResetTokenHash +passwordResetExpiresAt')
      .exec();
  },

  create(data) {
    return User.create(data);
  },
};

export default userRepository;
