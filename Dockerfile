# Stage 1: Build the frontend
FROM node:20-slim AS builder

# Set working directory
WORKDIR /app/frontend

# Copy frontend package files
COPY frontend/package.json frontend/package-lock.json ./

# Install dependencies
RUN npm ci

# Copy the rest of the frontend source code
COPY frontend/ ./

# Build the frontend
RUN npm run build

# Stage 2: Build the final image
FROM mcr.microsoft.com/playwright/go:v1.44.0-jammy

# Set working directory
WORKDIR /app

# Install Go
RUN apt-get update && apt-get install -y golang-go && rm -rf /var/lib/apt/lists/*

# Copy go module files
COPY go.mod go.sum ./

# Download Go dependencies
RUN go mod download

# Copy the rest of the backend source code
COPY . .

# Copy the built frontend from the builder stage
COPY --from=builder /app/frontend/dist ./frontend/dist

# Build the Go application
# CGO_ENABLED=0 is important for creating a static binary
# -ldflags="-s -w" strips debug information to reduce binary size
RUN CGO_ENABLED=0 GOOS=linux go build -v -o /app/server -ldflags="-s -w" main.go

# Expose the port the app runs on
EXPOSE 8080

# Set the entrypoint
ENTRYPOINT ["/app/server"]