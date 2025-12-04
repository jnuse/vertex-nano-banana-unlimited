# 项目分析报告

本文档包含了对 `vertex-nano-banana-unlimited` 项目的全面分析，涵盖了技术栈、项目架构、环境与依赖，以及代码结构。

## 1. 技术栈概览

项目采用前后端分离的技术架构。

### 后端 (Backend)
- **编程语言:** Go
- **核心库:**
  - `github.com/playwright-community/playwright-go`: 用于浏览器自动化，是实现核心功能的关键。
  - `github.com/disintegration/imaging`: 用于图像处理。
  - `github.com/joho/godotenv`: 用于加载 `.env` 文件中的环境变量。

### 前端 (Frontend)
- **编程语言:** TypeScript
- **核心框架:** React
- **构建工具:** Vite
- **UI & 样式:**
  - **Tailwind CSS**: 一个功能类优先的 CSS 框架。
  - **Radix UI**: 提供无样式的、可访问的基础 UI 组件。
  - **Lucide React**: 图标库。
  - **Framer Motion**: 用于实现丰富的动画效果。
  - **Fabric.js / Konva**: 用于处理 HTML5 Canvas 元素，支持复杂的图像编辑和交互。
- **状态管理:** Zustand
- **数据请求:** TanStack React Query (`@tanstack/react-query`)
- **API 客户端:**
    - `@google/genai`: 用于与 Google Generative AI 服务交互。

---

## 2. 项目架构分析

本项目是一个典型的**前后端分离架构** (Client-Server Architecture)。

- **前端 (Client)**：一个使用 React 和 TypeScript 构建的单页应用（SPA），负责用户界面、交互逻辑和客户端状态管理。
- **后端 (Server)**：一个使用 Go 语言编写的 HTTP API 服务器，负责处理核心业务逻辑，包括通过浏览器自动化进行图像生成、图像后期处理、文件存储（画廊功能）以及代理管理。

### 关系与调用流程图 (Mermaid)

```mermaid
graph TD
    subgraph Browser
        A[React UI Components]
    end

    subgraph Frontend (TypeScript/React)
        B(GeminiService Adapter)
        C(GoBackendService)
    end

    subgraph Backend (Go)
        D{HTTP Server API Endpoints<br>/run<br>/gallery<br>/proxy/subscriptions}
        E[Image Generation Logic<br>(run.go with Playwright)]
        F[Image/File System<br>(Gallery)]
        G[Proxy Management<br>(Sing-box)]
    end
    
    subgraph External Services
        H[Google AI Studio / Image Generation Service]
        I[Proxy Subscription URLs]
    end

    A -->|User Interaction| B
    B -->|Adapts Request| C
    C -->|HTTP API Calls| D
    
    D --> E
    D --> F
    D --> G

    E -->|Browser Automation| H
    G -->|Fetches Config| I
```

---

## 3. 环境与依赖分析

### 3.1 依赖项解析

#### 后端 Go 依赖 (`go.mod`)
- `github.com/disintegration/imaging v1.6.2`
- `github.com/joho/godotenv v1.5.1`
- `github.com/playwright-community/playwright-go v0.5200.1`

#### 前端 npm 依赖 (`frontend/package.json`)
前端依赖项众多，涵盖了从UI框架到状态管理的方方面面。

### 3.2 环境配置解读

项目通过根目录下的 `.env` 文件进行环境配置（以 `.env.example` 为模板）。

| 变量名                   | 用途                                                                     |
| -------------------------- | ------------------------------------------------------------------------ |
| `PROXY_SINGBOX_SUB_URLS`   | 用于配置 `sing-box` 代理的订阅链接。可以提供多个链接，用逗号分隔。 |

### 3.3 调试与追踪

为了应对浏览器自动化（尤其是在无头模式下）可能出现的各种问题，项目中集成了 **Playwright Tracing** 功能。

- **Trace Viewer**: Playwright 提供了一个强大的工具——Trace Viewer，它可以记录自动化脚本执行过程中的所有细节，包括网络请求、DOM变化、控制台日志和每个操作的截图。

当自动化流程失败时，会生成一个 `.zip` 格式的追踪文件。你可以通过以下命令在本地启动 Trace Viewer 来分析该文件，从而快速定位问题：

```bash
go run github.com/playwright-community/playwright-go/cmd/playwright@v0.5200.1 show-trace <path-to-trace.zip>
```

#### 代码实现示例

在 `internal/app/run.go` 的 `runScenario` 函数中，集成了完整的追踪生命周期管理：

```go
// ...

// 创建用于存储追踪文件的目录
traceDir := filepath.Join(opts.DownloadDir, "traces")
if err := os.MkdirAll(traceDir, 0o755); err != nil {
    return fail("create trace dir", fmt.Errorf("create trace dir: %w", err))
}

// 启动追踪
if err := browserCtx.Tracing().Start(playwright.TracingStartOptions{
    Name:        playwright.String(fmt.Sprintf("trace_%d.zip", id)),
    Screenshots: playwright.Bool(true), // 捕获截图
    Snapshots:   playwright.Bool(true), // 捕获DOM快照
    Sources:     playwright.Bool(true), // 包含源码
}); err != nil {
    return fail("start tracing", fmt.Errorf("start tracing: %w", err))
}

// 使用 defer 确保在函数退出时停止追踪
defer func() {
    // 停止追踪并将文件保存到指定路径
    traceFilePath := filepath.Join(traceDir, fmt.Sprintf("trace_%d.zip", id))
    if err := browserCtx.Tracing().Stop(traceFilePath); err != nil {
        fmt.Printf("⚠️ [%d] failed to stop tracing: %v\n", id, err)
    } else {
        fmt.Printf("ℹ️ [%d] 追踪文件已保存到: %s\n", id, traceFilePath)
    }

    if err := browserCtx.Close(); err != nil {
        fmt.Printf("⚠️ [%d] failed to close context: %v\n", id, err)
    }
}()

// ... 自动化操作代码 ...
```

---

## 4. 代码结构解析

### 4.1 目录结构说明

```
.
├── .devcontainer/       # 开发容器配置
├── .env.example         # 环境变量示例文件
├── frontend/            # 前端React应用源码
│   ├── src/             # 前端核心源码
│   │   ├── components/  # 可复用的React组件
│   │   ├── hooks/       # 自定义React Hooks
│   │   ├── services/    # 与API交互的服务
│   │   └── ...
│   ├── package.json     # 前端依赖配置
│   └── vite.config.ts   # Vite构建配置
├── internal/            # 后端Go应用内部源码
│   ├── app/             # 应用核心逻辑 (HTTP服务器、运行流程)
│   ├── imageprocessing/ # 图像处理功能
│   ├── proxy/           # 代理功能 (sing-box集成)
│   └── steps/           # 浏览器自动化步骤封装
├── main.go              # Go后端应用的入口文件
└── ...
```

### 4.2 关键文件定位

- **项目入口文件:**
  - **后端:** `main.go`
  - **前端:** `frontend/src/main.tsx`

- **主要配置文件:**
  - **后端:** `.env` (基于 `.env.example`)
  - **前端:** `frontend/vite.config.ts`
  - **依赖管理:** `go.mod` (后端), `frontend/package.json` (前端)

- **核心业务逻辑代码:**
  - **后端:**
    - `internal/app/server.go`: 定义了所有HTTP API端点。
    - `internal/app/run.go`: 核心的图像生成逻辑（浏览器自动化）。
    - `internal/proxy/singbox.go`: `sing-box` 代理集成实现。
  - **前端:**
    - `frontend/src/App.tsx`: React应用的根组件和UI布局。
    - `frontend/src/services/goBackendService.ts`: 封装了所有与Go后端API的通信。
    - `frontend/src/hooks/useImageGeneration.ts`: 管理图像生成流程状态的React Hook。