const express = require('express');
const bodyParser = require('body-parser');
const app = express();
const port = 4000;

app.use(bodyParser.urlencoded({ extended: true }));

// A simple in-memory store for authorization codes
const authCodes = new Map();

// /auth: The authorization endpoint
app.get('/auth', (req, res) => {
  const { client_id, redirect_uri, response_type, state } = req.query;
  if (response_type !== 'code') {
    return res.status(400).send('Invalid response_type');
  }

  // In a real provider, this would be a login and consent screen.
  // Here, we'll just auto-approve and generate a code.
  const code = Math.random().toString(36).substring(2, 15);
  authCodes.set(code, { clientId: client_id, user: { id: '123', email: 'test@example.com', name: 'Test User' } });

  const redirectUrl = `${redirect_uri}?code=${code}&state=${state}`;
  res.redirect(redirectUrl);
});

// /token: The token endpoint
app.post('/token', (req, res) => {
  const { client_id, client_secret, code, grant_type } = req.body;
  if (grant_type !== 'authorization_code') {
    return res.status(400).send('Invalid grant_type');
  }

  if (!authCodes.has(code)) {
    return res.status(400).send('Invalid code');
  }

  const { user } = authCodes.get(code);
  authCodes.delete(code); // Codes can only be used once

  res.json({
    access_token: 'mock_access_token',
    token_type: 'bearer',
  });
});

// /userinfo: The user info endpoint
app.get('/userinfo', (req, res) => {
  const authHeader = req.headers.authorization;
  if (authHeader !== 'Bearer mock_access_token') {
    return res.status(401).send('Unauthorized');
  }

  res.json({
    id: '123',
    email: 'oauth-user@example.com',
    name: 'OAuth User',
  });
});

app.listen(port, () => {
  console.log(`Mock OAuth server listening at http://localhost:${port}`);
});
