# Sandboxes

RabbitAI Lab 的沙箱镜像集合。每个子目录对应一个独立的 Docker 镜像，通过 GitHub Actions 自动构建并推送到 GitHub Container Registry (ghcr.io)。

## 镜像列表

| 镜像 | 目录 | 说明 |
|------|------|------|
| `ghcr.io/rabbitai-lab/claude-code` | `claude-code/` | 基于 Ubuntu 24.04，包含 Claude Code CLI、Node.js 22 LTS、常用开发工具 |
| `ghcr.io/rabbitai-lab/agent-browser` | `agent-browser/` | 基于 Ubuntu 24.04，包含 agent-browser CLI + Chromium（用于 AI Agent 浏览器自动化） |
| `ghcr.io/rabbitai-lab/dev-box` | `dev-box/` | 基于 Ubuntu 24.04 的通用开发环境：Node.js 24、pnpm、PM2、Claude Code、Python 3、JDK 8/21/26、Maven、Gradle 8.10/9.6.1、Nginx、GitHub CLI、browser-use CLI |

## 使用方式

```bash
# 拉取镜像
docker pull ghcr.io/rabbitai-lab/claude-code:latest

# 运行 Claude Code 沙箱（API Key 方式）
docker run -it --rm \
  -e ANTHROPIC_API_KEY=sk-ant-xxx \
  ghcr.io/rabbitai-lab/claude-code:latest \
  claude

# 运行 Agent Browser 沙箱
docker run -it --rm \
  -p 12345:12345 \
  ghcr.io/rabbitai-lab/agent-browser:latest \
  agent-browser dashboard start --port 12345

# 运行 Dev Box 沙箱（交互式 shell）
docker run -it --rm \
  -p 3000:3000 -p 8000:8000 -p 8080:8080 \
  ghcr.io/rabbitai-lab/dev-box:latest \
  /bin/bash
```

### 在 OpenSandbox 中使用

OpenSandbox 的 execd 代理会自动注入，无需预装：

```python
from opensandbox import Sandbox

sandbox = await Sandbox.create("ghcr.io/rabbitai-lab/claude-code:latest")
```

## 本地调试

进入镜像对应的目录，通过 docker compose 构建并运行。

> **注意**: 镜像基于 `linux/amd64` 构建，ARM64 Mac 用户需要使用 QEMU 模拟。首次构建较慢，请耐心等待。

```bash
# Claude Code 沙箱
cd claude-code
# 从本地 Dockerfile 构建镜像
docker compose build

# 构建并启动（首次推荐）
docker compose up -d --build

# 仅启动（已有镜像）
docker compose up -d

# 进入 Claude Code
docker exec -it claude-code claude
```

Claude Code 镜像启动后会自动拉起 sandbox-agent daemon（端口 2468）和看门狗。

```bash
# Agent Browser 沙箱
cd agent-browser

# 构建
docker compose build

# 启动
docker compose up -d
```

> **注意**: 运行 Claude Code 时需要设置环境变量 `ANTHROPIC_API_KEY`，可在 `docker compose up` 前 export 或在 `.env` 文件中配置。

## 仓库结构

```
Sandboxes/
├── .github/workflows/
│   ├── build-claude-code.yml       # Claude Code 独立构建 workflow
│   ├── build-agent-browser.yml     # Agent Browser 独立构建 workflow
│   └── build-dev-box.yml           # Dev Box 独立构建 workflow
├── claude-code/
│   └── Dockerfile
├── agent-browser/
│   └── Dockerfile
├── dev-box/
│   └── Dockerfile
├── .gitignore
└── README.md
```

## CI/CD

每个沙箱镜像对应一个独立的 GitHub Actions workflow 文件，仅监听自身目录的变更：

- 修改 `claude-code/**` → 仅触发 `build-claude-code.yml`
- 修改 `agent-browser/**` → 仅触发 `build-agent-browser.yml`
- 修改 `dev-box/**` → 仅触发 `build-dev-box.yml`
- 打 tag（如 `v0.1`）→ 所有镜像都会构建，附带版本号标签

每个镜像会自动打上以下标签：
- `latest` — 最新版本
- `sha-xxxxxxx` — 对应 commit SHA
- `vX.Y` — 当通过 tag 触发时附带版本号

## 新增镜像

1. **创建子目录和 Dockerfile**

   ```
   my-sandbox/
   └── Dockerfile
   ```

2. **创建对应的 workflow 文件**

   在 `.github/workflows/` 下新建 `build-my-sandbox.yml`，模板如下：

   ```yaml
   name: Build my-sandbox

   on:
     push:
       branches: [main]
       paths:
         - "my-sandbox/**"
         - ".github/workflows/build-my-sandbox.yml"
       tags:
         - "v*"
     workflow_dispatch:

   env:
     REGISTRY: ghcr.io
     IMAGE_NAME: my-sandbox

   jobs:
     build-and-push:
       runs-on: ubuntu-latest
       permissions:
         contents: read
         packages: write

       steps:
         - name: Checkout
           uses: actions/checkout@v4

         - name: Log in to Container Registry
           uses: docker/login-action@v3
           with:
             registry: ${{ env.REGISTRY }}
             username: ${{ github.actor }}
             password: ${{ secrets.GITHUB_TOKEN }}

         - name: Build and push
           run: |
             OWNER=$(echo "${{ github.repository_owner }}" | tr '[:upper:]' '[:lower:]')
             TAGS="${{ env.REGISTRY }}/${OWNER}/${{ env.IMAGE_NAME }}:latest,${{ env.REGISTRY }}/${OWNER}/${{ env.IMAGE_NAME }}:sha-${GITHUB_SHA:0:7}"
             if [ "${{ github.ref_type }}" = "tag" ]; then
               TAGS="${TAGS},${{ env.REGISTRY }}/${OWNER}/${{ env.IMAGE_NAME }}:${{ github.ref_name }}"
             fi
             docker build -t "${{ env.REGISTRY }}/${OWNER}/${{ env.IMAGE_NAME }}:latest" ${{ env.IMAGE_NAME }}
             for tag in $(echo "$TAGS" | tr ',' '\n'); do
               docker tag "${{ env.REGISTRY }}/${OWNER}/${{ env.IMAGE_NAME }}:latest" "$tag"
               docker push "$tag"
             done
   ```

3. **更新本 README 的镜像列表表格**

4. **提交并推送**，GitHub Actions 会自动构建

## 维护规范

### 版本发布

打 tag 即可发布版本，所有镜像都会构建并附上版本号标签：

```bash
git tag v0.2
git push origin v0.2
```

### Dockerfile 编写约定

- 基础镜像优先使用 `ubuntu:24.04`
- 必须创建非 root 用户 `sandbox`
- 工作目录统一为 `/workspace`
- 每层 RUN 末尾清理 apt 缓存：`rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/`
- 镜像名遵循 `ghcr.io/rabbitai-lab/<目录名>` 命名规则
