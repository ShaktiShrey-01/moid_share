import { validationResult } from 'express-validator';
import ApiError from '../utils/ApiError.js';

/**
 * Runs a list of express-validator chains, then aggregates any errors into a
 * single 422 ApiError. Usage:
 *   router.post('/x', validate([body('email').isEmail()]), controller.x)
 *
 * @param {Array} validations express-validator chains
 */
export default function validate(validations) {
  return async (req, _res, next) => {
    await Promise.all(validations.map((v) => v.run(req)));

    const result = validationResult(req);
    if (result.isEmpty()) return next();

    const details = result.array().map((e) => ({
      field: e.path ?? e.param,
      message: e.msg,
    }));
    return next(
      ApiError.unprocessable('Validation failed', {
        code: 'VALIDATION_ERROR',
        details,
      })
    );
  };
}
