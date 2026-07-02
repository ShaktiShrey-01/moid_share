import bcrypt from 'bcryptjs';
import config from '../config/env.js';

/**
 * Password hashing/verification. Isolated so the hashing algorithm/cost is a
 * one-file change and services never import bcrypt directly.
 */
const passwordService = {
  /** @param {string} plain @returns {Promise<string>} bcrypt hash */
  hash(plain) {
    return bcrypt.hash(plain, config.security.bcryptRounds);
  },

  /** @returns {Promise<boolean>} */
  compare(plain, hash) {
    if (!hash) return Promise.resolve(false);
    return bcrypt.compare(plain, hash);
  },
};

export default passwordService;
