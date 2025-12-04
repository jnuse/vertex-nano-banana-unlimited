# 使用微软官方提供的 Go & Node.js 基础镜像，它基于 Debian，非常稳定
FROM mcr.microsoft.com/devcontainers/go:1-bullseye

# 安装 Playwright 的系统依赖，并顺便更新一下 npm
# 我们在构建镜像时就解决掉所有依赖问题！
RUN sudo apt-get update && \
    sudo npx playwright install-deps chromium && \
    sudo npm install -g npm@latest && \
    sudo apt-get clean -y && \
    sudo rm -rf /var/lib/apt/lists/*

# [可选] 如果你需要特定的 Go 或 Node 版本，可以在这里添加命令来安装
# 例如: RUN su vscode -c "source /usr/local/share/nvm/nvm.sh && nvm install 18"
