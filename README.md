# MERN Full-Stack Sandbox (cli-arena-web-mern-sandbox)

This repository is a full-stack MERN (MongoDB, Express, React, Node.js) application designed as a sandbox for evaluating AI code generation agents.  
It includes a baseline application, a suite of tests, and 15 programming tasks of varying difficulty that build upon each other.

The application is fully containerized with Docker and managed via a simple Makefile interface.

## Table of Contents

- Architecture
- Setup and Usage
- Running Tests
- Task Index

## Architecture

The project is structured as a monorepo with two main packages: src/client (React/Vite) and src/server (Express/TypeScript).

- src/client: A modern React frontend built with Vite. It handles the user interface.
- src/server: A robust backend API built with Express and TypeScript. It follows a layered architecture (Controllers, Services, Repositories) to ensure separation of concerns.
- docker-compose.yml: Orchestrates the entire application stack, including the API, a MongoDB database, a Redis cache (added in a later task), and a Mongo Express GUI for easy database management.
- Makefile: Provides a simple, unified command interface (make setup, make build, make serve, make test, make lint) for managing the application lifecycle.
- tasks/: Contains 15 evaluation tasks, each with its own description, tests, and solution script.

See docs/architecture.md for more details.

## Setup and Usage

### Prerequisites

- Docker
- Docker Compose
- make

### Installation and Startup

1. Clone the repository:
   git clone <repo-url>
   cd cli-arena-web-mern-sandbox

2. Run the setup command:  
   This command builds the Docker images required for the development environment, which includes installing all npm dependencies for both the client and server.
   make setup

3. Start the application:  
   This will launch the entire stack (API, client, database, etc.) in detached mode.
   make serve

The application will be available at the following ports:
- Frontend UI: http://localhost:3000
- Backend API: http://localhost:8080
- Mongo Express GUI: http://localhost:8081

## Running Tests

To run the baseline backend API test suite:
make test

To run linting checks for both client and server:
make lint

To run End-to-End tests with Cypress (after completing the relevant task):
make serve
# In another terminal:
cd src/client && npm run e2e

## Task Index

This repository contains 15 tasks designed to test a range of software engineering skills. They are ordered logically and build upon one another.

| #  | ID                               | Title                                                  | Category              | Difficulty |
|----|----------------------------------|--------------------------------------------------------|-----------------------|------------|
| 1  | add-jwt-authentication           | Implement User Authentication System                   | Feature Development   | Medium     |
| 2  | add-role-based-access-control    | Add Role-Based Access Control (RBAC)                   | Feature Development   | Hard       |
| 3  | fix-jwt-race-condition           | Fix JWT Middleware Race Condition                      | Bug Fixes             | Hard       |
| 4  | add-security-enhancements        | Harden API with Security Best Practices                | Security              | Medium     |
| 5  | refactor-layered-architecture    | Refactor Backend to a Layered Architecture             | Refactoring           | Medium     |
| 6  | add-full-text-search             | Implement Full-Text Search for Products                | Feature Development   | Medium     |
| 7  | optimize-mongo-queries           | Optimize Product Query with Aggregation Pipeline       | Refactoring           | Hard       |
| 8  | add-websocket-notifications      | Implement Real-Time Product Notifications via WebSockets | Feature Development   | Hard       |
| 9  | fix-websocket-memory-leak        | Fix Memory Leak in WebSocket Service                   | Bug Fixes             | Hard       |
| 10 | add-file-upload-s3               | Implement Product Image Upload                         | Feature Development   | Hard       |
| 11 | refactor-react-components        | Refactor Frontend into Reusable React Components       | Refactoring           | Medium     |
| 12 | add-mock-payment-integration     | Integrate a Mock Payment Gateway for Checkout          | Feature Development   | Hard       |
| 13 | add-e2e-tests-cypress            | Add End-to-End (E2E) Tests with Cypress                | Testing               | Hard       |
| 14 | fix-mongo-transaction-rollback   | Fix Data Integrity with MongoDB Transactions           | Bug Fixes             | Hard       |
| 15 | devops-docker-healthcheck        | Improve Docker Compose Robustness with Healthchecks    | DevOps                | Hard       |
