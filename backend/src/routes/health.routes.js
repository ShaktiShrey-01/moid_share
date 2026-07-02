import { Router } from 'express';
import { liveness, readiness } from '../controllers/health.controller.js';

/**
 * Health/observability routes.
 *   GET /health        -> liveness (process up)
 *   GET /health/ready  -> readiness (dependencies up)
 */
const router = Router();

router.get('/', liveness);
router.get('/ready', readiness);

export default router;
