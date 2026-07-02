import { Router } from 'express';

import * as deviceController from '../controllers/device.controller.js';
import authenticate from '../middleware/authenticate.js';
import validate from '../middleware/validate.js';
import {
  registerDeviceValidator,
  deviceIdParamValidator,
  startPairingValidator,
  completePairingValidator,
} from '../validators/device.validators.js';

/**
 * Device routes, mounted at /api/v1/devices. Every route requires a valid
 * access token (device data is user-scoped).
 */
const router = Router();

router.use(authenticate);

router.get('/', deviceController.listDevices);
router.post('/', validate(registerDeviceValidator), deviceController.registerDevice);
router.delete('/:deviceId', validate(deviceIdParamValidator), deviceController.removeDevice);

router.post('/pair/start', validate(startPairingValidator), deviceController.startPairing);
router.post('/pair/complete', validate(completePairingValidator), deviceController.completePairing);

export default router;
