import mongoose from 'mongoose';
import { StatusCodes } from 'http-status-codes';
import { sendSuccess } from '../utils/ApiResponse.js';
import asyncHandler from '../utils/asyncHandler.js';

const MONGO_STATE = {
  0: 'disconnected',
  1: 'connected',
  2: 'connecting',
  3: 'disconnecting',
};

/**
 * Liveness probe — the process is up and serving. Cheap; never touches the DB.
 * Suitable for load-balancer/orchestrator liveness checks.
 */
export const liveness = asyncHandler(async (req, res) => {
  sendSuccess(res, StatusCodes.OK, {
    status: 'ok',
    uptimeSeconds: Math.round(process.uptime()),
    timestamp: new Date().toISOString(),
  });
});

/**
 * Readiness probe — the service is ready to handle requests, including its
 * dependencies (MongoDB). Returns 503 if the DB is not connected so a LB can
 * pull the instance out of rotation.
 */
export const readiness = asyncHandler(async (req, res) => {
  const dbState = mongoose.connection.readyState;
  const dbUp = dbState === 1;

  const payload = {
    status: dbUp ? 'ready' : 'degraded',
    dependencies: {
      database: MONGO_STATE[dbState] ?? 'unknown',
    },
    timestamp: new Date().toISOString(),
  };

  sendSuccess(
    res,
    dbUp ? StatusCodes.OK : StatusCodes.SERVICE_UNAVAILABLE,
    payload
  );
});
