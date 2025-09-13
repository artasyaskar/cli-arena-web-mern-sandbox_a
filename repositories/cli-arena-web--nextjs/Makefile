# Makefile for the cli-arena-web-nextjs project

# Stop if any command fails
.SHELLFLAGS = -ec

.PHONY: setup build serve test lint

# Install dependencies, initialize database
setup:
	@echo "Installing dependencies..."
	docker compose run --rm app sh -c "npm install --legacy-peer-deps"
	@echo "Generating Prisma client..."
	docker compose run --rm app sh -c "npx prisma generate"
	@echo "Setting up database..."
	docker compose run --rm app sh -c "npx prisma db push"
	@echo "Seeding database..."
	docker compose run --rm app sh -c "npm run db:seed"
	@echo "Setup complete!"

# Compile/build the application
build:
	@echo "Building application..."
	docker compose build

# Start the application locally
serve:
	@echo "Starting development server..."
	docker compose up -d
	@echo "Application started! Access at http://localhost:3000"

# Run all tests (must pass on clean checkout)
test:
	@echo "Running tests..."
	docker compose up -d
	docker compose exec app node --max_old_space_size=4096 ./node_modules/.bin/jest --runInBand --config jest.config.cjs --watchAll=false --passWithNoTests

# Run code quality checks
lint:
	@echo "Running linter..."
	docker compose run --rm app sh -c "npm run lint"
	@echo "Checking code formatting..."
	docker compose run --rm app sh -c "npm run format:check"
	@echo "Type checking..."
	docker compose run --rm app sh -c "npm run type-check"

# Stop all running containers
stop:
	@echo "Stopping all containers..."
	docker compose down

# Optional: force-reset Prisma schema & re-seed (⚠️ destructive)
prisma-reset:
	@echo "Resetting Prisma schema and database..."
	docker compose run --rm app sh -c "\
		npx prisma migrate reset --force && \
		npx prisma generate && \
		npm run db:seed"
