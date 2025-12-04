# Use the official Playwright image which has browser dependencies pre-installed
FROM mcr.microsoft.com/playwright/go:v1.44.0-jammy

# Set the working directory
WORKDIR /app

# --- Install Go and Node.js ---
# Install Go
RUN apt-get update && apt-get install -y golang-go && \
# Install Node.js 20.x
    apt-get install -y ca-certificates curl gnupg && \
    mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list && \
    apt-get update && apt-get install -y nodejs && \
# Clean up apt caches to reduce image size
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