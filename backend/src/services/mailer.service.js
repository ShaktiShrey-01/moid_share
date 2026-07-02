import logger from '../utils/logger.js';
import config from '../config/env.js';

/**
 * Mailer seam.
 *
 * Foundation ships a console mailer that logs the message (and, in dev, the
 * reset link) instead of sending real email. A production SMTP/provider
 * implementation replaces {@link mailerService} without touching callers.
 */
const mailerService = {
  /**
   * Sends a password-reset email.
   * @param {{ to: string, resetToken: string }} params
   */
  async sendPasswordReset({ to, resetToken }) {
    // A real implementation builds a deep link to the client reset screen.
    logger.info(`[mailer] password reset requested for ${to}`);
    if (!config.isProd) {
      logger.debug(`[mailer] DEV reset token for ${to}: ${resetToken}`);
    }
  },
};

export default mailerService;
