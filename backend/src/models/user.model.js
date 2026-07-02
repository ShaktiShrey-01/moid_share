import mongoose from 'mongoose';

/**
 * User account.
 *
 * Stores identity + profile only (no files, no clipboard). Passwords are stored
 * as a bcrypt hash and never selected by default (`select: false`). A user may
 * authenticate locally (email+password) and/or via Google (googleId).
 */
const userSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Name is required'],
      trim: true,
      maxlength: 80,
    },
    email: {
      type: String,
      required: [true, 'Email is required'],
      unique: true,
      lowercase: true,
      trim: true,
      index: true,
    },
    // Absent for Google-only accounts. Never returned to clients.
    passwordHash: {
      type: String,
      select: false,
    },
    googleId: {
      type: String,
      index: true,
      sparse: true,
    },
    avatarUrl: { type: String, default: null },
    // Which methods this account can use to sign in.
    providers: {
      type: [String],
      enum: ['local', 'google'],
      default: ['local'],
    },
    emailVerified: { type: Boolean, default: false },

    // Password reset (hashed token + expiry). Never returned to clients.
    passwordResetTokenHash: { type: String, select: false, default: null },
    passwordResetExpiresAt: { type: Date, select: false, default: null },
  },
  {
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true },
  }
);

/**
 * Public projection safe to send to clients — never leaks hashes/tokens.
 * @returns {object}
 */
userSchema.methods.toPublicJSON = function toPublicJSON() {
  return {
    id: this._id.toString(),
    name: this.name,
    email: this.email,
    avatarUrl: this.avatarUrl,
    providers: this.providers,
    emailVerified: this.emailVerified,
    createdAt: this.createdAt,
  };
};

const User = mongoose.model('User', userSchema);
export default User;
