import { test } from 'node:test';
import assert from 'node:assert/strict';

import registerTransferHandlers from '../src/sockets/transfer.socket.js';

/**
 * Fake Socket.IO socket that records `.on` handlers and captures what is
 * relayed via `.to(room).emit(...)`. No network, no auth, no Mongo — this
 * exercises the transfer signaling contract in isolation.
 */
function makeSocket({ userId = 'u1', deviceId = 'dev-A' } = {}) {
  const handlers = new Map();
  const emitted = []; // { room, event, message }

  const socket = {
    data: { userId, deviceId },
    on(event, cb) {
      handlers.set(event, cb);
    },
    to(room) {
      return {
        emit(event, message) {
          emitted.push({ room, event, message });
        },
      };
    },
  };

  registerTransferHandlers(/* io */ {}, socket);

  /** Invokes a registered inbound handler and returns its ack payload. */
  const fire = (event, payload) => {
    let ack;
    handlers.get(event)?.(payload, (res) => {
      ack = res;
    });
    return ack;
  };

  return { socket, emitted, fire, handlers };
}

test('offer relays to the sender room as transfer:incoming with metadata', () => {
  const { emitted, fire } = makeSocket();

  const ack = fire('transfer:offer', {
    transferId: 't1',
    fileName: 'report.pdf',
    size: 2048,
    contentType: 'application/pdf',
  });

  assert.deepEqual(ack, { ok: true });
  assert.equal(emitted.length, 1);
  const { room, event, message } = emitted[0];
  assert.equal(room, 'user:u1'); // only the user's own devices
  assert.equal(event, 'transfer:incoming');
  assert.equal(message.transferId, 't1');
  assert.equal(message.fileName, 'report.pdf');
  assert.equal(message.size, 2048);
  assert.equal(message.fromDeviceId, 'dev-A');
  assert.ok(message.at, 'stamps a timestamp');
});

test('accept / reject / cancel / complete map to their outbound events', () => {
  const { emitted, fire } = makeSocket();

  fire('transfer:accept', { transferId: 't1', sdp: 'x' });
  fire('transfer:reject', { transferId: 't2', reason: 'busy' });
  fire('transfer:cancel', { transferId: 't3' });
  fire('transfer:complete', { transferId: 't4', ok: true });

  const byEvent = Object.fromEntries(emitted.map((e) => [e.event, e.message]));
  assert.equal(byEvent['transfer:accepted'].transferId, 't1');
  assert.equal(byEvent['transfer:rejected'].reason, 'busy');
  assert.equal(byEvent['transfer:cancelled'].transferId, 't3');
  assert.equal(byEvent['transfer:completed'].ok, true);
});

test('missing transferId is rejected and nothing is relayed', () => {
  const { emitted, fire } = makeSocket();

  const ack = fire('transfer:offer', { fileName: 'x' });

  assert.deepEqual(ack, { ok: false, error: 'INVALID_PAYLOAD' });
  assert.equal(emitted.length, 0);
});

test('oversized control payload is rejected as TOO_LARGE', () => {
  const { emitted, fire } = makeSocket();

  const ack = fire('transfer:offer', {
    transferId: 't1',
    fileName: 'x',
    sdp: 'a'.repeat(17 * 1024), // exceeds 16 KB control cap
  });

  assert.deepEqual(ack, { ok: false, error: 'TOO_LARGE' });
  assert.equal(emitted.length, 0);
});
