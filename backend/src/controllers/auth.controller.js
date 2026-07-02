import { StatusCodes } from 'http-status-codes';
import authService from '../services/auth.service.js';
import { sendSuccess } from '../utils/ApiResponse.js';
import asyncHandler from '../utils/asyncHandler.js';

/**
 * Thin HTTP layer over {@link authService}. Controllers translate between
 * request/response and service calls only — no business logic here.
 */

export const register = asyncHandler(async (req, res) => {
  const { name, email, password, device } = req.body;
  const result = await authService.register({ name, email, password, device });
  sendSuccess(res, StatusCodes.CREATED, result);
});

export const login = asyncHandler(async (req, res) => {
  const { email, password, device } = req.body;
  const result = await authService.login({ email, password, device });
  sendSuccess(res, StatusCodes.OK, result);
});

export const refresh = asyncHandler(async (req, res) => {
  const { refreshToken, device } = req.body;
  const result = await authService.refresh({ refreshToken, device });
  sendSuccess(res, StatusCodes.OK, result);
});

export const logout = asyncHandler(async (req, res) => {
  await authService.logout({ refreshToken: req.body.refreshToken });
  sendSuccess(res, StatusCodes.OK, { message: 'Signed out' });
});

export const forgotPassword = asyncHandler(async (req, res) => {
  await authService.forgotPassword({ email: req.body.email });
  // Always 200 — never reveal whether the email exists.
  sendSuccess(res, StatusCodes.OK, {
    message: 'If that email exists, a reset link has been sent.',
  });
});

export const resetPassword = asyncHandler(async (req, res) => {
  await authService.resetPassword({
    token: req.body.token,
    password: req.body.password,
  });
  sendSuccess(res, StatusCodes.OK, { message: 'Password updated' });
});

export const google = asyncHandler(async (req, res) => {
  const { idToken, device } = req.body;
  const result = await authService.googleSignIn({ idToken, device });
  sendSuccess(res, StatusCodes.OK, result);
});

export const me = asyncHandler(async (req, res) => {
  const user = await authService.getMe(req.auth.userId);
  sendSuccess(res, StatusCodes.OK, { user });
});
