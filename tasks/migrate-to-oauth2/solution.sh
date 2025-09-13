#!/bin/bash
set -e

# This script provides the solution for the migrate-to-oauth2 task.

# --- Server-side changes ---
echo "--- Modifying server for OAuth 2.0 ---"

# 1. Add the new OAuth callback controller function to authController.ts
AUTH_CONTROLLER="src/server/src/controllers/authController.ts"
cat <<'EOF' >> $AUTH_CONTROLLER

export const oauthCallback = async (req: Request, res: Response) => {
  const { code } = req.query;

  if (!code) {
    return res.status(400).json({ message: 'Authorization code is missing' });
  }

  try {
    // Exchange code for token
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
    const tokenData = await tokenResponse.json();
    if (!tokenData.access_token) {
        throw new Error('Failed to get access token');
    }

    // Fetch user info
    const userResponse = await fetch('http://localhost:4000/userinfo', {
      headers: { Authorization: `Bearer ${tokenData.access_token}` },
    });
    const userInfo = await userResponse.json();

    // Find or create user
    let user = await User.findOne({ email: userInfo.email });
    if (!user) {
      user = new User({
        username: userInfo.name,
        email: userInfo.email,
        password: 'oauth_user', // Not used for login
      });
      await user.save();
    }

    // Generate JWT
    const token = jwt.sign({ id: user._id }, process.env.JWT_SECRET || 'your_jwt_secret', {
      expiresIn: '1h',
    });

    // Redirect to frontend with token
    res.cookie('token', token, { httpOnly: true });
    res.redirect('http://localhost:3000');

  } catch (error) {
    console.error('OAuth callback error:', error);
    res.status(500).json({ message: 'Server Error' });
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

# 3. Modify the App.tsx to change the login button
APP_TSX="src/client/src/App.tsx"
# This is a bit tricky with sed. We'll replace the whole login form.
# A simpler approach for a script is to just replace the whole file with a modified version.
# For this task, we'll just replace the line with the login button.
sed -i "s|<button>Login</button>|<a href=\"http:\/\/localhost:4000\/auth?response_type=code&client_id=your_client_id&redirect_uri=http:\/\/localhost:8080\/api\/auth\/oauth\/callback&state=12345\">Login with OAuth<\/a>|" $APP_TSX


echo "Migration to OAuth 2.0 completed."
