import { body } from 'express-validator';

/**
 * express-validator chains for auth endpoints. Kept separate from routes so the
 * rules are testable and reusable. Passwords: min 8 chars with letters+digits.
 */
const password = (field = 'password') =>
  body(field)
    .isString()
    .isLength({ min: 8, max: 128 })
    .withMessage('Password must be 8-128 characters')
    .matches(/[A-Za-z]/)
    .withMessage('Password must contain a letter')
    .matches(/\d/)
    .withMessage('Password must contain a number');

const email = body('email')
  .isEmail()
  .withMessage('A valid email is required')
  .normalizeEmail();

const optionalDevice = [
  body('device.id').optional().isString().trim(),
  body('device.name').optional().isString().trim(),
  body('device.platform').optional().isString().trim(),
];

export const registerValidator = [
  body('name').isString().trim().isLength({ min: 1, max: 80 }),
  email,
  password(),
  ...optionalDevice,
];

export const loginValidator = [
  email,
  body('password').isString().notEmpty(),
  ...optionalDevice,
];

export const refreshValidator = [
  body('refreshToken').isString().notEmpty(),
  ...optionalDevice,
];

export const logoutValidator = [body('refreshToken').isString().notEmpty()];

export const forgotPasswordValidator = [email];

export const resetPasswordValidator = [
  body('token').isString().notEmpty(),
  password(),
];

export const googleValidator = [
  body('idToken').isString().notEmpty(),
  ...optionalDevice,
];
