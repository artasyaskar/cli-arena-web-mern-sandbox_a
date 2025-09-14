const express = require('express');
const bodyParser = require('body-parser');
const app = express();
const port = 4000;

app.use(bodyParser.urlencoded({ extended: true }));

const authCodes = new Map();

// /auth: The authorization endpoint
app.get('/auth', (req, res) => {
  const { client_id, redirect_uri, response_type, state } = req.query;
  if (response_type !== 'code') {
    return res.status(400).send('Invalid response_type');
  }
  const code = Math.random().toString(36).substring(2, 15);
  authCodes.set(code, { clientId: client_id, user: { id: '123', email: 'test@example.com', name: 'Test User' } });
  const redirectUrl = `${redirect_uri}?code=${code}&state=${state}`;
  res.redirect(redirectUrl);
});

// /token: The token endpoint
app.post('/token', (req, res) => {
  const { code } = req.body;
  if (!authCodes.has(code)) {
    return res.status(400).json({ error: 'invalid_grant', error_description: 'Invalid authorization code' });
  }
  authCodes.delete(code);
  res.json({ access_token: 'mock_access_token', token_type: 'bearer' });
});

// /token_error: A token endpoint that always returns an error
app.post('/token_error', (req, res) => {
  res.status(401).json({ error: 'unauthorized_client' });
});

// /token_timeout: A token endpoint that simulates a network timeout
app.post('/token_timeout', (req, res) => {
  setTimeout(() => {
    res.json({ access_token: 'mock_access_token', token_type: 'bearer' });
  }, 5000); // 5 second delay
});


// /userinfo: The user info endpoint
app.get('/userinfo', (req, res) => {
  const authHeader = req.headers.authorization;
  if (authHeader !== 'Bearer mock_access_token') {
    return res.status(401).send('Unauthorized');
  }
  res.json({ id: '123', email: 'oauth-user@example.com', name: 'OAuth User' });
});

app.listen(port, () => {
  console.log(`Mock OAuth server listening at http://localhost:${port}`);
});
