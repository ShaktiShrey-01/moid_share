import { test } from 'node:test';
import assert from 'node:assert/strict';

import passwordService from '../src/services/password.service.js';

test('hash then compare succeeds; wrong password fails', async () => {
  const hash = await passwordService.hash('Sup3rSecret');
  assert.notEqual(hash, 'Sup3rSecret');
  assert.equal(await passwordService.compare('Sup3rSecret', hash), true);
  assert.equal(await passwordService.compare('wrong', hash), false);
});

test('compare against missing hash returns false', async () => {
  assert.equal(await passwordService.compare('x', undefined), false);
});
