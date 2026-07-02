import { Router } from 'express';
import config from '../config/env.js';
import healthRoutes from './health.routes.js';

/**
 * Mounts all versioned feature routers under the configured API prefix.
 *
 * Feature routers (auth, users, devices, settings, pairing) are registered
 * here as they are built, keeping route composition in one predictable place.
 *
 * @param {import('express').Application} app
 */
export default function registerRoutes(app) {
  const v1 = Router();

  v1.use('/health', healthRoutes);
  // v1.use('/auth', authRoutes);      // Step 3
  // v1.use('/users', userRoutes);     // Step 3+
  // v1.use('/devices', deviceRoutes); // later

  app.use(config.server.apiPrefix, v1);
}
