import { test } from 'node:test';
import assert from 'node:assert/strict';

import tokenService, { parseDurationMs } from '../src/services/token.service.js';

test('access token signs and verifies round-trip', () => {
  const token = tokenService.signAccessToken('user-123');
  const payload = tokenService.verifyAccessToken(token);
  assert.equal(payload.sub, 'user-123');
  assert.equal(payload.type, 'access');
});

test('verifyAccessToken rejects a tampered token', () => {
  const token = tokenService.signAccessToken('user-123');
  const tampered = `${token}x`;
  assert.throws(() => tokenService.verifyAccessToken(tampered));
});

test('hashToken is deterministic and 64 hex chars (sha256)', () => {
  const a = tokenService.hashToken('abc');
  const b = tokenService.hashToken('abc');
  assert.equal(a, b);
  assert.match(a, /^[0-9a-f]{64}$/);
});

test('generateRefreshToken returns 96 hex chars (48 bytes)', () => {
  const raw = tokenService.generateRefreshToken();
  assert.match(raw, /^[0-9a-f]{96}$/);
});

test('parseDurationMs handles units and raw seconds', () => {
  assert.equal(parseDurationMs('15m'), 15 * 60_000);
  assert.equal(parseDurationMs('30d'), 30 * 86_400_000);
  assert.equal(parseDurationMs('45s'), 45_000);
  assert.equal(parseDurationMs(10), 10_000);
  assert.throws(() => parseDurationMs('nope'));
});
