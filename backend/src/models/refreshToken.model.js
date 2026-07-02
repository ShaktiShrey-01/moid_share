import mongoose from 'mongoose';

/**
 * Persisted refresh-token session.
 *
 * We store only a SHA-256 hash of the opaque refresh token (never the raw
 * value), enabling server-side revocation and rotation. Each row represents one
 * device session. A TTL index auto-purges expired rows.
 */
const refreshTokenSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    // SHA-256 hex of the raw refresh token.
    tokenHash: { type: String, required: true, index: true },
    // Optional device metadata for the "registered devices" UI.
    device: {
      id: { type: String, default: null },
      name: { type: String, default: null },
      platform: { type: String, default: null },
    },
    expiresAt: { type: Date, required: true },
    revokedAt: { type: Date, default: null },
    // Set when this token is rotated, pointing at its successor (audit trail).
    replacedByHash: { type: String, default: null },
  },
  { timestamps: true }
);

// TTL: Mongo removes documents once `expiresAt` passes.
refreshTokenSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });

refreshTokenSchema.virtual('isActive').get(function isActive() {
  return !this.revokedAt && this.expiresAt.getTime() > Date.now();
});

const RefreshToken = mongoose.model('RefreshToken', refreshTokenSchema);
export default RefreshToken;
