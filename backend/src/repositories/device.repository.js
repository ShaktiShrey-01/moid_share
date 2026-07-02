import Device from '../models/device.model.js';

/** Data access for {@link Device}. */
const deviceRepository = {
  listByUser(userId) {
    return Device.find({ user: userId }).sort({ lastSeenAt: -1 }).exec();
  },

  findByUserAndDeviceId(userId, deviceId) {
    return Device.findOne({ user: userId, deviceId }).exec();
  },

  /** Creates or updates the device row for (user, deviceId). */
  upsert(userId, deviceId, data) {
    return Device.findOneAndUpdate(
      { user: userId, deviceId },
      { $set: { ...data, user: userId, deviceId, lastSeenAt: new Date() } },
      { new: true, upsert: true, setDefaultsOnInsert: true }
    ).exec();
  },

  deleteByUserAndDeviceId(userId, deviceId) {
    return Device.deleteOne({ user: userId, deviceId }).exec();
  },

  /** Adds each device to the other's pairedWith list (idempotent). */
  async linkPair(userId, deviceIdA, deviceIdB) {
    await Promise.all([
      Device.updateOne(
        { user: userId, deviceId: deviceIdA },
        { $addToSet: { pairedWith: deviceIdB } }
      ).exec(),
      Device.updateOne(
        { user: userId, deviceId: deviceIdB },
        { $addToSet: { pairedWith: deviceIdA } }
      ).exec(),
    ]);
  },
};

export default deviceRepository;
