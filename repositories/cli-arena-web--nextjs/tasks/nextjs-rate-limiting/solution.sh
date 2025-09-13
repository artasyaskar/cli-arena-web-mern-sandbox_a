#!/bin/bash

# 1. Create rate limiting utility
mkdir -p src/lib
cat > src/lib/rateLimit.ts << 'EOF'
interface RateLimitEntry {
  count: number
  resetTime: number
}

class RateLimiter {
  private store: Map<string, RateLimitEntry> = new Map()
  private readonly limit: number
  private readonly windowMs: number

  constructor(limit: number = 5, windowMs: number = 60000) {
    this.limit = limit
    this.windowMs = windowMs
  }

  isAllowed(identifier: string): boolean {
    const now = Date.now()
    const entry = this.store.get(identifier)

    if (!entry || now > entry.resetTime) {
      this.store.set(identifier, {
        count: 1,
        resetTime: now + this.windowMs
      })
      return true
    }

    if (entry.count >= this.limit) {
      return false
    }

    entry.count++
    return true
  }

  getRemainingRequests(identifier: string): number {
    const entry = this.store.get(identifier)
    if (!entry || Date.now() > entry.resetTime) {
      return this.limit
    }
    return Math.max(0, this.limit - entry.count)
  }

  getResetTime(identifier: string): number {
    const entry = this.store.get(identifier)
    return entry ? entry.resetTime : Date.now() + this.windowMs
  }

  cleanup(): void {
    const now = Date.now()
    for (const [key, entry] of this.store.entries()) {
      if (now > entry.resetTime) {
        this.store.delete(key)
      }
    }
  }
}

const rateLimiter = new RateLimiter()

export function checkRateLimit(identifier: string): {
  allowed: boolean
  remaining: number
  resetTime: number
} {
  rateLimiter.cleanup()
  
  const allowed = rateLimiter.isAllowed(identifier)
  const remaining = rateLimiter.getRemainingRequests(identifier)
  const resetTime = rateLimiter.getResetTime(identifier)

  return { allowed, remaining, resetTime }
}
EOF

# 2. Create rate limited API route
mkdir -p src/pages/api
cat > src/pages/api/limited.ts << 'EOF'
import type { NextApiRequest, NextApiResponse } from 'next'
import { checkRateLimit } from '../../lib/rateLimit'

export default function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method not allowed' })
  }

  // Get client IP
  const clientIP = req.headers['x-forwarded-for'] || 
                  req.headers['x-real-ip'] || 
                  req.connection.remoteAddress || 
                  'unknown'

  const identifier = Array.isArray(clientIP) ? clientIP[0] : clientIP

  // Check rate limit
  const { allowed, remaining, resetTime } = checkRateLimit(identifier)

  // Set rate limit headers
  res.setHeader('X-RateLimit-Limit', '5')
  res.setHeader('X-RateLimit-Remaining', remaining.toString())
  res.setHeader('X-RateLimit-Reset', new Date(resetTime).toISOString())

  if (!allowed) {
    res.setHeader('Retry-After', Math.ceil((resetTime - Date.now()) / 1000).toString())
    return res.status(429).json({
      error: 'Rate limit exceeded',
      message: 'Too many requests, please try again later',
      retryAfter: Math.ceil((resetTime - Date.now()) / 1000)
    })
  }

  res.status(200).json({
    message: 'Success',
    timestamp: new Date().toISOString(),
    remainingRequests: remaining
  })
}
EOF
