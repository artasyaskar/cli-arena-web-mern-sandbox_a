# Architecture Overview

This document provides a high-level overview of the MERN Full-Stack Sandbox architecture.

## Core Philosophy

The project is designed as a monorepo containing a separate frontend client and backend server. The entire stack is containerized using Docker to ensure a consistent and reproducible environment for development, testing, and evaluation. A `Makefile` provides a simple, unified interface for common tasks.

## Service Architecture (Docker Compose)

The `docker-compose.yml` file defines the following services:

-   **`api`**: The main backend service. It is built from the `Dockerfile` and runs the Node.js/Express server. It exposes the API on port 8080. For development, it uses the `development` stage of the Dockerfile, which includes dev dependencies and enables hot-reloading.
-   **`mongo`**: The primary database service, using the official `mongo` image. It is configured to run as a replica set, which is necessary for MongoDB transactions (as required by a later task). Data is persisted in a named volume (`mongo-data`).
-   **`redis`**: A Redis service for caching or other tasks, added in a later task. It uses the official `redis` image.
-   **`mongo-express`**: A web-based GUI for managing the MongoDB database, which is extremely useful for debugging and inspecting data. It is accessible on port 8081.

The `api` service is configured with healthchecks and wait scripts to ensure it only starts after its dependencies (`mongo`, `redis`) are healthy, preventing startup race conditions.

## Backend Architecture (Node.js/Express)

The backend, located in `src/server`, is built with TypeScript and follows a layered (or N-tier) architecture to promote separation of concerns.

1.  **Routes (`src/server/src/routes`)**: Defines the API endpoints and maps them to controller functions. It is responsible for handling HTTP methods and pathing.
2.  **Middleware (`src/server/src/middleware`)**: Contains middleware functions for tasks like authentication (`protect`), authorization (`admin`), input validation, and file uploads (`multer`).
3.  **Controllers (`src/server/src/controllers`)**: The API layer. A controller's job is to handle the `request` and `response` objects. It parses incoming requests, calls the appropriate service method with the required data, and formats the response to be sent back to the client. It does not contain business logic.
4.  **Services (`src/server/src/services`)**: The Business Logic Layer (BLL). This is where all business rules, logic, and orchestration happen. For example, the `authService` handles the logic for checking if a user exists and comparing passwords. Services are called by controllers and call upon the repository layer to access data.
5.  **Repositories (`src/server/src/repositories`)**: The Data Access Layer (DAL). This layer is responsible for all direct communication with the database. It abstracts the database queries (e.g., Mongoose calls) away from the rest of the application. Services use repositories to fetch and persist data without needing to know the underlying database implementation.
6.  **Models (`src/server/src/models`)**: Defines the Mongoose schemas for the database collections (e.g., `User`, `Product`).

This layered approach makes the backend more modular, easier to maintain, and easier to test, as each layer can be tested in isolation.

## Frontend Architecture (React)

The frontend, located in `src/client`, is a single-page application (SPA) built with React and Vite. After a refactoring task, it is structured into a set of reusable components located in `src/client/src/components`.

-   **`App.tsx`**: The top-level component, responsible for main state management (like authentication status and routing between views) and composing the main application layout.
-   **`components/`**: Contains smaller, single-purpose components like `ProductList`, `AuthForm`, `SearchBar`, etc., which are imported into `App.tsx` or other container components.
-   **State Management**: Primarily uses React hooks (`useState`, `useEffect`, `useCallback`).
-   **API Communication**: Uses the `axios` library to make requests to the backend API. The Vite development server is configured with a proxy to the backend to avoid CORS issues.
