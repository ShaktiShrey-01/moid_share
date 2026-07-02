import crypto from 'node:crypto';

import deviceRepository from '../repositories/device.repository.js';
import pairingCodeRepository from '../repositories/pairingCode.repository.js';
import ApiError from '../utils/ApiError.js';

/**
 * Device registration + pairing business logic.
 *
 * Pairing links two devices of the SAME user (e.g. an Android phone and a Mac):
 * one device requests a short code, the other confirms it, and both record each
 * other in `pairedWith`. The trust link is later used by transfer/clipboard.
 */
const PAIRING_TTL_MS = 5 * 60 * 1000; // 5 minutes

const deviceService = {
  list(userId) {
    return deviceRepository
      .listByUser(userId)
      .then((docs) => docs.map((d) => d.toPublicJSON()));
  },

  async register(userId, { deviceId, name, platform, model, pushToken }) {
    const device = await deviceRepository.upsert(userId, deviceId, {
      name,
      platform,
      model,
      pushToken,
    });
    return device.toPublicJSON();
  },

  async remove(userId, deviceId) {
    const result = await deviceRepository.deleteByUserAndDeviceId(
      userId,
      deviceId
    );
    if (result.deletedCount === 0) {
      throw ApiError.notFound('Device not found', { code: 'DEVICE_NOT_FOUND' });
    }
  },

  /** Starts pairing from a device: returns a single-use code + expiry. */
  async startPairing(userId, initiatorDeviceId) {
    const device = await deviceRepository.findByUserAndDeviceId(
      userId,
      initiatorDeviceId
    );
    if (!device) {
      throw ApiError.badRequest('Register this device before pairing', {
        code: 'DEVICE_NOT_REGISTERED',
      });
    }

    await pairingCodeRepository.invalidateForDevice(userId, initiatorDeviceId);

    // 6-digit numeric code, cryptographically random.
    const code = String(crypto.randomInt(0, 1_000_000)).padStart(6, '0');
    const expiresAt = new Date(Date.now() + PAIRING_TTL_MS);
    await pairingCodeRepository.create({
      user: userId,
      code,
      initiatorDeviceId,
      expiresAt,
    });

    return { code, expiresAt };
  },

  /** Completes pairing from the confirming device using the code. */
  async completePairing(userId, { code, deviceId }) {
    const pairing = await pairingCodeRepository.findUsableByCode(userId, code);
    if (!pairing) {
      throw ApiError.badRequest('Invalid or expired pairing code', {
        code: 'PAIRING_INVALID',
      });
    }
    if (pairing.initiatorDeviceId === deviceId) {
      throw ApiError.badRequest('Cannot pair a device with itself', {
        code: 'PAIRING_SELF',
      });
    }

    await deviceRepository.linkPair(
      userId,
      pairing.initiatorDeviceId,
      deviceId
    );
    await pairingCodeRepository.consume(pairing._id);

    const [a, b] = await Promise.all([
      deviceRepository.findByUserAndDeviceId(userId, pairing.initiatorDeviceId),
      deviceRepository.findByUserAndDeviceId(userId, deviceId),
    ]);

    return {
      paired: [a?.toPublicJSON(), b?.toPublicJSON()].filter(Boolean),
    };
  },
};

export default deviceService;
