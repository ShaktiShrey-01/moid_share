import { Router } from 'express';

import * as authController from '../controllers/auth.controller.js';
import authenticate from '../middleware/authenticate.js';
import validate from '../middleware/validate.js';
import { authRateLimiter } from '../middleware/authRateLimiter.js';
import {
  registerValidator,
  loginValidator,
  refreshValidator,
  logoutValidator,
  forgotPasswordValidator,
  resetPasswordValidator,
  googleValidator,
} from '../validators/auth.validators.js';

/**
 * Authentication routes, mounted at /api/v1/auth.
 * Credential endpoints get the stricter auth rate limiter.
 */
const router = Router();

router.post('/register', authRateLimiter, validate(registerValidator), authController.register);
router.post('/login', authRateLimiter, validate(loginValidator), authController.login);
router.post('/refresh', validate(refreshValidator), authController.refresh);
router.post('/logout', validate(logoutValidator), authController.logout);
router.post('/forgot-password', authRateLimiter, validate(forgotPasswordValidator), authController.forgotPassword);
router.post('/reset-password', validate(resetPasswordValidator), authController.resetPassword);
router.post('/google', authRateLimiter, validate(googleValidator), authController.google);

router.get('/me', authenticate, authController.me);

export default router;
