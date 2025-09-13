#!/bin/bash

# 1. Install dependencies
npm install next-auth @next-auth/prisma-adapter

# 2. Create environment variables
cat > .env.local << 'EOF'
NEXTAUTH_URL=http://localhost:3000
NEXTAUTH_SECRET=your-secret-key-here
GITHUB_ID=your-github-client-id
GITHUB_SECRET=your-github-client-secret
EOF

# 3. Create NextAuth API route
mkdir -p src/pages/api/auth
cat > src/pages/api/auth/[...nextauth].ts << 'EOF'
import NextAuth from 'next-auth'
import GithubProvider from 'next-auth/providers/github'
import { PrismaAdapter } from '@next-auth/prisma-adapter'
import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient()

export default NextAuth({
  adapter: PrismaAdapter(prisma),
  providers: [
    GithubProvider({
      clientId: process.env.GITHUB_ID!,
      clientSecret: process.env.GITHUB_SECRET!,
    }),
  ],
  session: {
    strategy: 'jwt',
  },
  callbacks: {
    async signIn({ user, account, profile }) {
      if (account?.provider === 'github') {
        const existingUser = await prisma.user.findUnique({
          where: { email: user.email! },
        })

        if (existingUser) {
          await prisma.user.update({
            where: { email: user.email! },
            data: { githubId: profile?.id?.toString() },
          })
        }
      }
      return true
    },
    async session({ session, token }) {
      if (token) {
        session.user.id = token.sub!
      }
      return session
    },
    async jwt({ token, user }) {
      if (user) {
        token.sub = user.id
      }
      return token
    },
  },
})
EOF

# 4. Update _app.tsx
cat > src/pages/_app.tsx << 'EOF'
import type { AppProps } from 'next/app'
import { SessionProvider } from 'next-auth/react'

export default function App({ Component, pageProps: { session, ...pageProps } }: AppProps) {
  return (
    <SessionProvider session={session}>
      <Component {...pageProps} />
    </SessionProvider>
  )
}
EOF

# 5. Create session API route
cat > src/pages/api/session.ts << 'EOF'
import { getServerSession } from 'next-auth'
import { NextApiRequest, NextApiResponse } from 'next'
import { authOptions } from './auth/[...nextauth]'

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method not allowed' })
  }

  const session = await getServerSession(req, res, authOptions)

  if (session) {
    res.status(200).json({
      authenticated: true,
      user: session.user,
    })
  } else {
    res.status(200).json({
      authenticated: false,
    })
  }
}
EOF

# 6. Create protected API route
cat > src/pages/api/protected.ts << 'EOF'
import { getServerSession } from 'next-auth'
import { NextApiRequest, NextApiResponse } from 'next'
import { authOptions } from './auth/[...nextauth]'

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method not allowed' })
  }

  const session = await getServerSession(req, res, authOptions)

  if (!session) {
    return res.status(401).json({ error: 'Authentication required' })
  }

  res.status(200).json({
    message: 'This is a protected API route',
    user: session.user,
  })
}
EOF

# 7. Create logout API route
cat > src/pages/api/logout.ts << 'EOF'
import { NextApiRequest, NextApiResponse } from 'next'

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' })
  }

  res.setHeader('Set-Cookie', [
    'next-auth.session-token=; Path=/; Expires=Thu, 01 Jan 1970 00:00:00 GMT',
    'next-auth.csrf-token=; Path=/; Expires=Thu, 01 Jan 1970 00:00:00 GMT',
    '__Secure-next-auth.session-token=; Path=/; Expires=Thu, 01 Jan 1970 00:00:00 GMT; Secure',
    '__Secure-next-auth.csrf-token=; Path=/; Expires=Thu, 01 Jan 1970 00:00:00 GMT; Secure',
  ])

  res.status(200).json({ message: 'Logged out successfully' })
}
EOF
