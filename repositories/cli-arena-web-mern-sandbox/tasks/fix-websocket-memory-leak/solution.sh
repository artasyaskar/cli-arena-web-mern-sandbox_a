#!/usr/bin/env bash
set -euo pipefail

# This script fixes the memory leak in the WebSocket service.

echo "--- Applying solution for task: fix-websocket-memory-leak ---"

# The fix is to remove the event listener when a client disconnects.
# We will overwrite the websockets.ts file with the corrected logic.

cat > src/server/src/websockets.ts << 'EOF'
import { WebSocketServer, WebSocket } from 'ws';
import { Server } from 'http';
import eventBus from './event-bus';

let wss: WebSocketServer;

export const initWebSocketServer = (server: Server) => {
  wss = new WebSocketServer({ server });

  wss.on('connection', (ws: WebSocket) => {
    console.log('Client connected to WebSocket');

    const handleSomeEvent = () => {
      if (ws.readyState === WebSocket.OPEN) {
          ws.send(JSON.stringify({ type: 'INTERNAL_EVENT' }));
      }
    };
    eventBus.on('some-event', handleSomeEvent);


    ws.on('close', () => {
      console.log('Client disconnected');
      // THE FIX: Remove the listener to prevent a memory leak.
      eventBus.off('some-event', handleSomeEvent);
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

echo "--- Memory leak fixed successfully. ---"
