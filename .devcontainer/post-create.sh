#!/bin/bash

echo "🚀 Starting post-create setup..."

# 1. 安装 Go 依赖
echo "📦 Installing Go dependencies..."
go mod tidy

# 2. 安装 Playwright 浏览器
# 注意: 我们用了你的 README 中指定的版本
echo "🌐 Installing Playwright Chromium browser..."
go run github.com/playwright-community/playwright-go/cmd/playwright@v0.5200.1 install chromium

# 3. 安装前端依赖
echo "📦 Installing frontend dependencies..."
cd frontend
npm install
cd ..

echo "✅ All set! Your dev environment is ready to use."
