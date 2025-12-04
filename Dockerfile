# Use the official Playwright image which has browser dependencies pre-installed
FROM mcr.microsoft.com/playwright:v1.44.0-jammy

# Set the working directory
WORKDIR /app

# --- Install Go ---
# The base image already has Node.js. We only need to add Go.
RUN apt-get update && \
    apt-get install -y golang-go && \
    rm -rf /var/lib/apt/lists/*

# --- Setup Backend ---
# Copy go module files and download dependencies to leverage Docker cache
COPY go.mod go.sum ./
RUN go mod download && go mod tidy

# --- Setup Frontend ---
# Copy package files and install dependencies to leverage Docker cache
COPY frontend/package.json frontend/package-lock.json ./frontend/
RUN npm --prefix frontend ci

# --- Install Playwright Dependencies and Browser ---
# This step is crucial and comes from post-create.sh
RUN npx playwright install-deps && \
    go run github.com/playwright-community/playwright-go/cmd/playwright@v0.5200.1 install chromium

# --- Copy Source Code ---
# Copy the rest of the source code
COPY . .

# --- Expose Ports ---
# Expose Go backend port
EXPOSE 8080
# Expose Vite frontend dev server port
EXPOSE 5173

# --- Entrypoint ---
# Use a script to start both services
COPY .devcontainer/start-dev.sh /usr/local/bin/start-dev.sh
RUN chmod +x /usr/local/bin/start-dev.sh

ENTRYPOINT ["/usr/local/bin/start-dev.sh"]