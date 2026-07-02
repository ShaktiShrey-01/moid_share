import mongoose from 'mongoose';

/**
 * A device registered to a user (Android phone, Mac, etc.).
 *
 * `deviceId` is a stable client-generated identifier (persisted on-device), so
 * re-registering the same physical device upserts rather than duplicates. Two
 * devices of the same user can be *paired* to establish an explicit trust link
 * used by the transfer/clipboard features.
 *
 * Stores metadata only — never files or clipboard contents.
 */
const deviceSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    // Stable, client-generated id (uuid). Unique per user.
    deviceId: { type: String, required: true },
    name: { type: String, required: true, trim: true, maxlength: 100 },
    platform: {
      type: String,
      enum: ['android', 'ios', 'macos', 'windows', 'linux', 'web', 'unknown'],
      default: 'unknown',
    },
    model: { type: String, default: null },
    // Optional push token for future notifications (never required).
    pushToken: { type: String, default: null },
    lastSeenAt: { type: Date, default: Date.now },
    // deviceIds this device is paired with (same user).
    pairedWith: { type: [String], default: [] },
  },
  { timestamps: true }
);

// One row per (user, deviceId).
deviceSchema.index({ user: 1, deviceId: 1 }, { unique: true });

deviceSchema.methods.toPublicJSON = function toPublicJSON() {
  return {
    id: this._id.toString(),
    deviceId: this.deviceId,
    name: this.name,
    platform: this.platform,
    model: this.model,
    lastSeenAt: this.lastSeenAt,
    pairedWith: this.pairedWith,
    createdAt: this.createdAt,
  };
};

const Device = mongoose.model('Device', deviceSchema);
export default Device;
