import { test } from 'node:test';
import assert from 'node:assert/strict';
import request from 'supertest';

import { createApp } from '../src/app.js';

const app = createApp();

test('register rejects invalid body with 422 validation envelope', async () => {
  const res = await request(app)
    .post('/api/v1/auth/register')
    .send({ name: '', email: 'not-an-email', password: 'short' });

  assert.equal(res.status, 422);
  assert.equal(res.body.success, false);
  assert.equal(res.body.error.code, 'VALIDATION_ERROR');
  assert.ok(Array.isArray(res.body.error.details));
  assert.ok(res.body.error.details.length >= 1);
});

test('login requires email and password (422)', async () => {
  const res = await request(app).post('/api/v1/auth/login').send({});
  assert.equal(res.status, 422);
  assert.equal(res.body.error.code, 'VALIDATION_ERROR');
});

test('GET /me without token returns 401', async () => {
  const res = await request(app).get('/api/v1/auth/me');
  assert.equal(res.status, 401);
  assert.equal(res.body.success, false);
  assert.equal(res.body.error.code, 'AUTH_HEADER_MISSING');
});

test('GET /me with malformed token returns 401', async () => {
  const res = await request(app)
    .get('/api/v1/auth/me')
    .set('Authorization', 'Bearer not.a.jwt');
  assert.equal(res.status, 401);
  assert.equal(res.body.success, false);
});
