FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# 1. 安装基础工具
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    wget \
    jq \
    ca-certificates \
    gnupg \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/

# 2. 安装 Node.js 22 LTS
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/

# 3. 安装 agent-browser、Chrome 及 MCP Server
RUN npm install -g agent-browser @rabbitai-lab/agent-browser-mcp \
    && agent-browser install --with-deps \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/

# 4. 创建非 root 用户和 workspace
RUN groupadd -r sandbox && useradd -r -g sandbox -G audio,video -s /bin/bash sandbox \
    && mkdir -p /home/sandbox /workspace \
    && chown -R sandbox:sandbox /home/sandbox /workspace

# 暴露端口
# 12345 - Dashboard Web UI (启动命令: agent-browser dashboard start --port 12345)
# 9222 - Chrome DevTools Protocol (CDP)
# 12346 - WebSocket Streaming (启动命令: agent-browser stream enable --port 12346)
# 12347 - MCP Server (启动命令: agent-browser-mcp --port 12347)
EXPOSE 12345 9222 12346 12347

WORKDIR /workspace
USER sandbox

CMD ["bash"]
