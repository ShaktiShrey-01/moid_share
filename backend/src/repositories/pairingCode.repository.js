import PairingCode from '../models/pairingCode.model.js';

/** Data access for {@link PairingCode}. */
const pairingCodeRepository = {
  create(data) {
    return PairingCode.create(data);
  },

  findUsableByCode(userId, code) {
    return PairingCode.findOne({
      user: userId,
      code,
      consumedAt: null,
      expiresAt: { $gt: new Date() },
    }).exec();
  },

  consume(id) {
    return PairingCode.updateOne(
      { _id: id },
      { $set: { consumedAt: new Date() } }
    ).exec();
  },

  /** Clears any prior active codes for a device before issuing a new one. */
  invalidateForDevice(userId, initiatorDeviceId) {
    return PairingCode.updateMany(
      { user: userId, initiatorDeviceId, consumedAt: null },
      { $set: { consumedAt: new Date() } }
    ).exec();
  },
};

export default pairingCodeRepository;
