# MERN SANDBOX MAKEFILE

# Colors
GREEN := \033[0;32m
RED   := \033[0;31m
YELLOW:= \033[1;33m
RESET := \033[0m

# Use .PHONY to ensure these targets run even if files with the same name exist.
.PHONY: all setup build serve stop test lint lint-server lint-client clean logs

# Default target
all: setup build serve

# Target: setup
# Builds the Docker images required for the development environment.
setup:
	@echo "$(YELLOW)--- Setting up development environment ---$(RESET)"
	@docker-compose build \
		&& echo "$(GREEN)✅ Setup complete$(RESET)" \
		|| (echo "$(RED)❌ Setup failed$(RESET)" && exit 1)

# Target: build
# Builds the lean, production-ready Docker image.
build:
	@echo "$(YELLOW)--- Building production image ---$(RESET)"
	@docker build --target production -t cli-arena-web-mern-sandbox:latest . \
		&& echo "$(GREEN)✅ Build complete$(RESET)" \
		|| (echo "$(RED)❌ Build failed$(RESET)" && exit 1)

# Target: serve
# Starts all application services in detached mode.
serve:
	@echo "$(YELLOW)--- Starting application stack ---$(RESET)"
	@docker-compose up -d \
		&& echo "$(GREEN)✅ Services started$(RESET)" \
		|| (echo "$(RED)❌ Failed to start services$(RESET)" && exit 1)

# Target: stop
# Stops and removes all application containers.
stop:
	@echo "$(YELLOW)--- Stopping application stack ---$(RESET)"
	@docker-compose down \
		&& echo "$(GREEN)✅ Services stopped$(RESET)" \
		|| (echo "$(RED)❌ Failed to stop services$(RESET)" && exit 1)

# Target: test
# Runs the backend test suite inside the 'api' service container.
test:
	@echo "$(YELLOW)--- Running backend tests ---$(RESET)"
	@docker-compose exec -T api sh -c "cd /app/server && NODE_OPTIONS=--experimental-vm-modules npx jest --config=/app/server/jest.config.js --runInBand --passWithNoTests --no-cache" \
		&& echo "$(GREEN)✅ Tests passed$(RESET)" \
		|| (echo "$(RED)❌ Tests failed$(RESET)" && exit 1)

# Target: lint
# Runs linting for both the server and client code.
lint: lint-server lint-client
	@echo "$(GREEN)🎉 All lint checks passed$(RESET)"

# Target: lint-server
# Runs ESLint for the server-side TypeScript code.
lint-server:
	@echo "$(YELLOW)--- Linting server code ---$(RESET)"
	@docker-compose exec -T api npm run lint \
		&& echo "$(GREEN)✅ Server lint passed$(RESET)" \
		|| (echo "$(RED)❌ Server lint failed$(RESET)" && exit 1)

# Target: lint-client
# Runs ESLint for the client-side React/TypeScript code.
lint-client:
	@echo "$(YELLOW)--- Linting client code ---$(RESET)"
	@docker-compose exec -T api npm run lint --prefix ../client \
		&& echo "$(GREEN)✅ Client lint passed$(RESET)" \
		|| (echo "$(RED)❌ Client lint failed$(RESET)" && exit 1)

# Target: clean
# Stops containers and removes volumes, including the database.
# USE WITH CAUTION.
clean:
	@echo "$(YELLOW)--- Cleaning up Docker environment (containers, networks, volumes) ---$(RESET)"
	@docker-compose down -v --remove-orphans \
		&& echo "$(GREEN)✅ Cleanup complete$(RESET)" \
		|| (echo "$(RED)❌ Cleanup failed$(RESET)" && exit 1)

# Target: logs
# Follows the logs from all services.
logs:
	@echo "$(YELLOW)--- Tailing logs ---$(RESET)"
	@docker-compose logs -f
