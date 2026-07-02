import { body, param } from 'express-validator';

const deviceId = (field = 'deviceId') =>
  body(field).isString().trim().isLength({ min: 8, max: 128 });

export const registerDeviceValidator = [
  deviceId(),
  body('name').isString().trim().isLength({ min: 1, max: 100 }),
  body('platform')
    .optional()
    .isIn(['android', 'ios', 'macos', 'windows', 'linux', 'web', 'unknown']),
  body('model').optional().isString().trim(),
  body('pushToken').optional().isString().trim(),
];

export const deviceIdParamValidator = [
  param('deviceId').isString().trim().isLength({ min: 8, max: 128 }),
];

export const startPairingValidator = [deviceId('initiatorDeviceId')];

export const completePairingValidator = [
  body('code').isString().trim().isLength({ min: 6, max: 6 }),
  deviceId(),
];
