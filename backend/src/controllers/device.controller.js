import { StatusCodes } from 'http-status-codes';
import deviceService from '../services/device.service.js';
import { sendSuccess } from '../utils/ApiResponse.js';
import asyncHandler from '../utils/asyncHandler.js';

/** Thin HTTP layer over {@link deviceService}. All routes are authenticated. */

export const listDevices = asyncHandler(async (req, res) => {
  const devices = await deviceService.list(req.auth.userId);
  sendSuccess(res, StatusCodes.OK, { devices });
});

export const registerDevice = asyncHandler(async (req, res) => {
  const device = await deviceService.register(req.auth.userId, req.body);
  sendSuccess(res, StatusCodes.OK, { device });
});

export const removeDevice = asyncHandler(async (req, res) => {
  await deviceService.remove(req.auth.userId, req.params.deviceId);
  sendSuccess(res, StatusCodes.OK, { message: 'Device removed' });
});

export const startPairing = asyncHandler(async (req, res) => {
  const result = await deviceService.startPairing(
    req.auth.userId,
    req.body.initiatorDeviceId
  );
  sendSuccess(res, StatusCodes.CREATED, result);
});

export const completePairing = asyncHandler(async (req, res) => {
  const result = await deviceService.completePairing(req.auth.userId, req.body);
  sendSuccess(res, StatusCodes.OK, result);
});
