#!/bin/bash

# 1. Create job queue utility
mkdir -p src/lib
cat > src/lib/jobQueue.ts << 'EOF'
interface Job {
  id: string
  task: string
  status: 'pending' | 'completed'
  createdAt: Date
}

class JobQueue {
  private jobs: Map<string, Job> = new Map()

  enqueue(task: string): string {
    const id = Math.random().toString(36).substring(2, 15)
    const job: Job = {
      id,
      task,
      status: 'pending',
      createdAt: new Date()
    }

    this.jobs.set(id, job)

    // Auto-complete job after 3 seconds
    setTimeout(() => {
      this.completeJob(id)
    }, 3000)

    return id
  }

  getJob(id: string): Job | undefined {
    return this.jobs.get(id)
  }

  private completeJob(id: string): void {
    const job = this.jobs.get(id)
    if (job) {
      job.status = 'completed'
      this.jobs.set(id, job)
    }
  }

  getAllJobs(): Job[] {
    return Array.from(this.jobs.values())
  }
}

// Singleton instance
const jobQueue = new JobQueue()

export default jobQueue
EOF

# 2. Create enqueue API route
mkdir -p src/pages/api
cat > src/pages/api/enqueue.ts << 'EOF'
import type { NextApiRequest, NextApiResponse } from 'next'
import jobQueue from '../../lib/jobQueue'

export default function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' })
  }

  try {
    const { task } = req.body

    if (!task || typeof task !== 'string') {
      return res.status(400).json({ error: 'Task is required and must be a string' })
    }

    const jobId = jobQueue.enqueue(task)

    res.status(200).json({ id: jobId })
  } catch (error) {
    console.error('Enqueue error:', error)
    res.status(500).json({ error: 'Internal server error' })
  }
}
EOF

# 3. Create status API route
cat > src/pages/api/status.ts << 'EOF'
import type { NextApiRequest, NextApiResponse } from 'next'
import jobQueue from '../../lib/jobQueue'

export default function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method not allowed' })
  }

  try {
    const { id } = req.query

    if (!id || typeof id !== 'string') {
      return res.status(400).json({ error: 'Job ID is required' })
    }

    const job = jobQueue.getJob(id)

    if (!job) {
      return res.status(404).json({ error: 'Job not found' })
    }

    res.status(200).json({ status: job.status })
  } catch (error) {
    console.error('Status error:', error)
    res.status(500).json({ error: 'Internal server error' })
  }
}
EOF
