import mongoose from 'mongoose';

/**
 * Short-lived pairing code linking two devices of the same user.
 *
 * The initiating device creates a code; the other device confirms it. A TTL
 * index removes codes shortly after they expire. Codes are single-use.
 */
const pairingCodeSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    // 6-digit human-enterable code (unique while active).
    code: { type: String, required: true, index: true },
    // The device that started pairing (its stable deviceId).
    initiatorDeviceId: { type: String, required: true },
    consumedAt: { type: Date, default: null },
    expiresAt: { type: Date, required: true },
  },
  { timestamps: true }
);

pairingCodeSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });

pairingCodeSchema.virtual('isUsable').get(function isUsable() {
  return !this.consumedAt && this.expiresAt.getTime() > Date.now();
});

const PairingCode = mongoose.model('PairingCode', pairingCodeSchema);
export default PairingCode;
