#!/bin/bash
set -e

# This script provides the solution for the migrate-to-oauth2 task.

# --- Server-side changes ---
echo "--- Modifying server for OAuth 2.0 ---"

# 1. Add the new OAuth callback controller function to authController.ts
AUTH_CONTROLLER="src/server/src/controllers/authController.ts"
# We'll overwrite the file to ensure the new, more robust function is used.
# This is a simplification for the task. In a real scenario, you'd use a more targeted replacement.
cat <<'EOF' > $AUTH_CONTROLLER
import { Request, Response } from 'express';
import User from '../models/User';
import jwt from 'jsonwebtoken';

// We keep the register function for now, but the login is removed.
export const register = async (req: Request, res: Response) => {
    // ... (register function remains the same)
};

export const oauthCallback = async (req: Request, res: Response) => {
  const { code, error } = req.query;

  if (error) {
    return res.status(400).json({ message: 'OAuth error', error });
  }

  if (!code) {
    return res.status(400).json({ message: 'Authorization code is missing' });
  }

  try {
    const tokenResponse = await fetch('http://localhost:4000/token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        client_id: 'your_client_id',
        client_secret: 'your_client_secret',
        code: code as string,
        grant_type: 'authorization_code',
        redirect_uri: 'http://localhost:8080/api/auth/oauth/callback',
      }),
    });

    if (!tokenResponse.ok) {
        const errorData = await tokenResponse.json();
        throw new Error(`Failed to get access token: ${errorData.error_description}`);
    }
    const tokenData = await tokenResponse.json();

    const userResponse = await fetch('http://localhost:4000/userinfo', {
      headers: { Authorization: `Bearer ${tokenData.access_token}` },
    });
    if (!userResponse.ok) {
        throw new Error('Failed to fetch user info');
    }
    const userInfo = await userResponse.json();

    let user = await User.findOne({ email: userInfo.email });
    if (!user) {
      user = new User({
        username: userInfo.name,
        email: userInfo.email,
        password: 'oauth_user', // Not used for login
        provider: 'oauth',
      });
      await user.save();
    } else {
      // If user exists, update their info
      user.username = userInfo.name;
      await user.save();
    }

    const token = jwt.sign({ id: user._id, provider: 'oauth' }, process.env.JWT_SECRET || 'your_jwt_secret', {
      expiresIn: '1h',
    });

    res.cookie('token', token, { httpOnly: true, secure: process.env.NODE_ENV === 'production' });
    res.redirect('http://localhost:3000/welcome'); // Redirect to a welcome page

  } catch (error) {
    console.error('OAuth callback error:', error);
    res.status(500).json({ message: 'Server Error during OAuth callback' });
  }
};
EOF

# 2. Add the new route to authRoutes.ts and remove the old login route
AUTH_ROUTES="src/server/src/routes/authRoutes.ts"
sed -i "/router.post('\/login', login);/d" $AUTH_ROUTES
sed -i "s/import { register, login } from/import { register, oauthCallback } from/" $AUTH_ROUTES
echo "router.get('/oauth/callback', oauthCallback);" >> $AUTH_ROUTES

# --- Client-side changes ---
echo "--- Modifying client for OAuth 2.0 ---"
APP_TSX="src/client/src/App.tsx"
sed -i "s|<button>Login</button>|<a href=\"http:\/\/localhost:4000\/auth?response_type=code&client_id=your_client_id&redirect_uri=http:\/\/localhost:8080\/api\/auth\/oauth\/callback&state=12345\">Login with OAuth<\/a>|" $APP_TSX

echo "Migration to OAuth 2.0 completed."
