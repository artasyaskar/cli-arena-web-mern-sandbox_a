# Stage 0: Development environment
# Has all source code and all dependencies (dev + prod)
FROM node:18-alpine AS development
WORKDIR /app

# Install server dependencies
COPY src/server/package*.json ./server/
RUN cd server && npm install --include=dev

# Install client dependencies
COPY src/client/package*.json ./client/
RUN cd client && npm install

# Copy all source code
COPY . .
WORKDIR /app/server


# Stage 1: Build the client for production
# Starts from 'development' to ensure it has all needed tools
FROM development AS client-builder
WORKDIR /app/client
# Copy client source files
COPY src/client/ ./
# Ensure dependencies are there, then build
RUN npm install
RUN npm run build


# Stage 2: Build the server for production
FROM development AS server-builder
WORKDIR /app/server
# Copy server source files
COPY src/server/ ./
# Install dependencies and build
RUN npm install
RUN npm run build


# Stage 3: Final Production image
# A lean image with only what's needed to run the app
FROM node:18-alpine AS production
WORKDIR /app

# Copy server production dependencies and install them
COPY --from=server-builder /app/server/package.json ./
COPY --from=server-builder /app/server/package-lock.json ./
RUN npm install --production

# Copy built server code from server-builder stage
COPY --from=server-builder /app/server/dist ./dist

# Copy built client assets from client-builder stage to be served by Express
COPY --from=client-builder /app/client/dist ./public

EXPOSE 8080
CMD ["node", "dist/index.js"]