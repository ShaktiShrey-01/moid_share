import { test } from 'node:test';
import assert from 'node:assert/strict';
import request from 'supertest';

import { createApp } from '../src/app.js';

const app = createApp();

test('device routes require authentication (401 without token)', async () => {
  const list = await request(app).get('/api/v1/devices');
  assert.equal(list.status, 401);

  const register = await request(app)
    .post('/api/v1/devices')
    .send({ deviceId: 'android-abc12345', name: 'Pixel' });
  assert.equal(register.status, 401);

  const pair = await request(app)
    .post('/api/v1/devices/pair/start')
    .send({ initiatorDeviceId: 'android-abc12345' });
  assert.equal(pair.status, 401);
});
