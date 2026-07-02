import { test } from 'node:test';
import assert from 'node:assert/strict';
import request from 'supertest';

import { createApp } from '../src/app.js';

const app = createApp();

test('GET /api/v1/health returns liveness envelope', async () => {
  const res = await request(app).get('/api/v1/health');

  assert.equal(res.status, 200);
  assert.equal(res.body.success, true);
  assert.equal(res.body.data.status, 'ok');
  assert.equal(typeof res.body.data.uptimeSeconds, 'number');
  assert.ok(res.headers['x-request-id'], 'sets a correlation id header');
});

test('GET /api/v1/health/ready reports degraded when DB is down', async () => {
  const res = await request(app).get('/api/v1/health/ready');

  // No Mongo connection in unit tests -> readiness must signal 503.
  assert.equal(res.status, 503);
  assert.equal(res.body.data.status, 'degraded');
  assert.equal(res.body.data.dependencies.database, 'disconnected');
});

test('unknown route returns the standard 404 error envelope', async () => {
  const res = await request(app).get('/api/v1/does-not-exist');

  assert.equal(res.status, 404);
  assert.equal(res.body.success, false);
  assert.equal(res.body.error.code, 'ROUTE_NOT_FOUND');
});

test('security headers are applied (helmet) and x-powered-by is hidden', async () => {
  const res = await request(app).get('/api/v1/health');

  assert.ok(res.headers['x-content-type-options'], 'helmet header present');
  assert.equal(res.headers['x-powered-by'], undefined);
});
