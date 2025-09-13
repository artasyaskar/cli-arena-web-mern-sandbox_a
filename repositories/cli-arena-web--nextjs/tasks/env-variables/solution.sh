#!/bin/bash

# 1. Install dependencies
npm install dotenv

# 2. Create environment files
cat > .env << 'EOF'
API_URL=https://api.example.com
DATABASE_URL=postgresql://user:password@localhost:5432/mydb
NEXT_PUBLIC_APP_NAME=CLI Arena
NEXT_PUBLIC_API_BASE_URL=https://api.example.com
NODE_ENV=development
PORT=3000
EOF

cat > .env.example << 'EOF'
API_URL=https://api.example.com
DATABASE_URL=postgresql://user:password@localhost:5432/mydb
NEXT_PUBLIC_APP_NAME=Your App Name
NEXT_PUBLIC_API_BASE_URL=https://api.example.com
NODE_ENV=development
PORT=3000
EOF

# 3. Update next.config.js
cat > next.config.js << 'EOF'
/** @type {import('next').NextConfig} */
const nextConfig = {
  experimental: {
    appDir: true,
  },
  output: 'standalone',
  env: {
    NEXT_PUBLIC_APP_NAME: process.env.NEXT_PUBLIC_APP_NAME,
    NEXT_PUBLIC_API_BASE_URL: process.env.NEXT_PUBLIC_API_BASE_URL,
  },
  serverRuntimeConfig: {
    apiUrl: process.env.API_URL,
    databaseUrl: process.env.DATABASE_URL,
  },
  publicRuntimeConfig: {
    appName: process.env.NEXT_PUBLIC_APP_NAME,
    apiBaseUrl: process.env.NEXT_PUBLIC_API_BASE_URL,
  },
}

module.exports = nextConfig
EOF

# 4. Create index page
cat > src/pages/index.tsx << 'EOF'
import { GetServerSideProps } from 'next'
import getConfig from 'next/config'

interface HomeProps {
  serverSideEnvVars: {
    apiUrl: string
    databaseUrl: string
    nodeEnv: string
  }
  clientSideEnvVars: {
    appName: string
    apiBaseUrl: string
  }
}

export default function Home({ serverSideEnvVars, clientSideEnvVars }: HomeProps) {
  return (
    <div style={{ padding: '20px', fontFamily: 'Arial, sans-serif' }}>
      <h1>Environment Variables Demo</h1>
      
      <h2>Server-Side Environment Variables</h2>
      <p>These are loaded on the server and passed as props:</p>
      <ul>
        <li><strong>API URL:</strong> {serverSideEnvVars.apiUrl}</li>
        <li><strong>Database URL:</strong> {serverSideEnvVars.databaseUrl}</li>
        <li><strong>Node Environment:</strong> {serverSideEnvVars.nodeEnv}</li>
      </ul>

      <h2>Client-Side Environment Variables</h2>
      <p>These are accessible directly in the browser:</p>
      <ul>
        <li><strong>App Name:</strong> {clientSideEnvVars.appName}</li>
        <li><strong>API Base URL:</strong> {clientSideEnvVars.apiBaseUrl}</li>
      </ul>

      <h2>Direct Environment Variable Access</h2>
      <p>Environment variables with NEXT_PUBLIC_ prefix are available directly:</p>
      <ul>
        <li><strong>NEXT_PUBLIC_APP_NAME:</strong> {process.env.NEXT_PUBLIC_APP_NAME}</li>
        <li><strong>NEXT_PUBLIC_API_BASE_URL:</strong> {process.env.NEXT_PUBLIC_API_BASE_URL}</li>
      </ul>
    </div>
  )
}

export const getServerSideProps: GetServerSideProps = async () => {
  const { serverRuntimeConfig } = getConfig()
  
  return {
    props: {
      serverSideEnvVars: {
        apiUrl: process.env.API_URL || 'Not set',
        databaseUrl: process.env.DATABASE_URL || 'Not set',
        nodeEnv: process.env.NODE_ENV || 'Not set',
      },
      clientSideEnvVars: {
        appName: process.env.NEXT_PUBLIC_APP_NAME || 'Not set',
        apiBaseUrl: process.env.NEXT_PUBLIC_API_BASE_URL || 'Not set',
      },
    },
  }
}
EOF

# 5. Create API route
cat > src/pages/api/env-demo.ts << 'EOF'
import type { NextApiRequest, NextApiResponse } from 'next'

export default function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method not allowed' })
  }

  res.status(200).json({
    serverSide: {
      apiUrl: process.env.API_URL,
      databaseUrl: process.env.DATABASE_URL,
      nodeEnv: process.env.NODE_ENV,
    },
    clientSide: {
      appName: process.env.NEXT_PUBLIC_APP_NAME,
      apiBaseUrl: process.env.NEXT_PUBLIC_API_BASE_URL,
    },
    message: 'Environment variables from API route'
  })
}
EOF

# 6. Create Node.js script
mkdir -p scripts
cat > scripts/env-demo.js << 'EOF'
require('dotenv').config()

console.log('Environment Variables Demo Script')
console.log('================================')

console.log('\nServer-side variables:')
console.log('API_URL:', process.env.API_URL)
console.log('DATABASE_URL:', process.env.DATABASE_URL)
console.log('NODE_ENV:', process.env.NODE_ENV)

console.log('\nClient-side variables:')
console.log('NEXT_PUBLIC_APP_NAME:', process.env.NEXT_PUBLIC_APP_NAME)
console.log('NEXT_PUBLIC_API_BASE_URL:', process.env.NEXT_PUBLIC_API_BASE_URL)

console.log('\nAll environment variables:')
Object.keys(process.env).forEach(key => {
  if (key.startsWith('NEXT_PUBLIC_') || key === 'API_URL' || key === 'DATABASE_URL' || key === 'NODE_ENV') {
    console.log(`${key}: ${process.env[key]}`)
  }
})
EOF
