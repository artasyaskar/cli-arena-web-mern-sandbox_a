import mongoose from 'mongoose';
import { Server } from 'http';
import WebSocket from 'ws';
import app from '../../../src/server/src/index';
import eventBus from '../../../src/server/src/event-bus';

const MONGO_URI_TEST = process.env.MONGO_URI_TEST || 'mongodb://mongo:27017/mern-sandbox-test-memleak';

let server: Server;
let port: number;

beforeAll((done) => {
  mongoose.connect(MONGO_URI_TEST).then(() => {
    server = app.listen(0, async () => {
      const address = server.address();
      port = typeof address === 'string' ? 0 : address!.port;
      done();
    });
  });
});

afterAll((done) => {
  mongoose.connection.close().then(() => {
    server.close(done);
  });
});

describe('WebSocket Memory Leak', () => {
  it('should not accumulate event listeners as clients connect and disconnect', async () => {
    const initialListenerCount = eventBus.listenerCount('some-event');
    const connectionCount = 20;

    const createAndCloseConnection = (): Promise<void> => {
      return new Promise((resolve, reject) => {
        const ws = new WebSocket(`ws://localhost:${port}`);
        ws.on('open', () => {
          ws.close();
        });
        ws.on('close', () => {
          resolve();
        });
        ws.on('error', (err) => {
          reject(err);
        });
      });
    };

    // Create and close connections sequentially
    for (let i = 0; i < connectionCount; i++) {
      await createAndCloseConnection();
    }

    const finalListenerCount = eventBus.listenerCount('some-event');

    // The buggy code will have `finalListenerCount` as `initialListenerCount + connectionCount`.
    // The correct code will have them be equal.
    expect(finalListenerCount).toBe(initialListenerCount);
  }, 20000); // Increase timeout for this test
});
