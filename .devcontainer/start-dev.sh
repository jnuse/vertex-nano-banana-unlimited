#!/bin/bash

# Start the Go backend in the background
echo "--- Starting Go backend server ---"
go run . &

# Wait a few seconds for the backend to initialize
sleep 5

# Start the Vite frontend dev server in the foreground
echo "--- Starting Vite frontend dev server ---"
# We need to run this from the /app/frontend directory
cd /app/frontend && npm run dev -- --host 0.0.0.0