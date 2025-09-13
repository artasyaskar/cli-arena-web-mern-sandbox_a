# CLI Arena Web Next.js

A sandbox repository for evaluating AI agents with realistic developer tasks. Built with Next.js, TypeScript, PostgreSQL, and Prisma.

## 🚀 Quick Setup

### Prerequisites

- Docker and Docker Compose

### Setup Steps

1. **Clone the repository:**

   ```bash
   git clone <repository-url>
   cd cli-arena-web-nextjs
   ```

2. **Install dependencies and setup database:**

   ```bash
   make setup
   ```

3. **Start the application:**

   ```bash
   make serve
   ```

4. **Access the application:**
   - Main app: http://localhost:3000
   - API endpoints: http://localhost:3000/api
   - Prisma Studio: http://localhost:5555

## 🛠️ Available Commands

```bash
make setup          # Install dependencies and initialize database
make build          # Build the application
make serve          # Start development server
make test           # Run all tests
make lint           # Run code quality checks
make stop           # Stop all containers
```

## 📁 Project Structure

```
├── src/                    # Application source code
│   └── pages/api/         # API routes
├── tasks/                  # Task definitions for AI agents
├── prisma/                # Database schema
├── scripts/               # Utility scripts
├── Dockerfile             # Container configuration
├── docker-compose.yml     # Multi-service orchestration
└── Makefile               # Development commands
```

## 🎯 For AI Agents

This repository contains task definitions in the `/tasks` directory. Each task includes:

- `task.yaml` - Task requirements and metadata
- `solution.sh` - Reference implementation
- `tests/test.sh` - Validation script

## 📄 License

MIT License
