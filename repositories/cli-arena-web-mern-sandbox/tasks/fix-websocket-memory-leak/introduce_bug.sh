#!/usr/bin/env bash
set -euo pipefail

# This script introduces a memory leak into the WebSocket service.

echo "--- Introducing bug for task: fix-websocket-memory-leak ---"

# 1. Create a global event bus
cat > src/server/src/event-bus.ts << 'EOF'
import { EventEmitter } from 'events';

// A singleton event emitter for application-wide events
const eventBus = new EventEmitter();

export default eventBus;
EOF


# 2. Modify the WebSocket service to use the event bus and create the leak
# We will overwrite the existing websockets.ts file with the buggy version.
cat > src/server/src/websockets.ts << 'EOF'
import { WebSocketServer, WebSocket } from 'ws';
import { Server } from 'http';
import eventBus from './event-bus';

let wss: WebSocketServer;

export const initWebSocketServer = (server: Server) => {
  wss = new WebSocketServer({ server });

  wss.on('connection', (ws: WebSocket) => {
    console.log('Client connected to WebSocket');

    // THE BUG: A new listener is created for every connection.
    const handleSomeEvent = () => {
      // In a real app, this might do something important.
      // For the test, it just needs to exist.
      if (ws.readyState === WebSocket.OPEN) {
          ws.send(JSON.stringify({ type: 'INTERNAL_EVENT' }));
      }
    };
    eventBus.on('some-event', handleSomeEvent);


    ws.on('close', () => {
      console.log('Client disconnected');
      // The listener `handleSomeEvent` is NOT removed here, causing a memory leak.
    });
  });

  console.log('WebSocket server initialized');
};

export const broadcast = (message: object) => {
  if (!wss) {
    console.error('WebSocket server not initialized.');
    return;
  }

  const data = JSON.stringify(message);
  wss.clients.forEach((client) => {
    if (client.readyState === WebSocket.OPEN) {
      client.send(data);
    }
  });
};
EOF

echo "--- Memory leak introduced successfully. ---"
