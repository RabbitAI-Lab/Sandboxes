FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# 1. 安装基础工具 + Chrome 运行所需的系统依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    wget \
    jq \
    socat \
    ca-certificates \
    gnupg \
    libxcb-shm0 \
    libx11-xcb1 \
    libx11-6 \
    libxcb1 \
    libxext6 \
    libxrandr2 \
    libxcomposite1 \
    libxcursor1 \
    libxdamage1 \
    libxfixes3 \
    libxi6 \
    libgtk-3-0 \
    libpangocairo-1.0-0 \
    libpango-1.0-0 \
    libatk1.0-0 \
    libcairo-gobject2 \
    libcairo2 \
    libgdk-pixbuf-2.0-0 \
    libxrender1 \
    libasound2t64 \
    libfreetype6 \
    libfontconfig1 \
    libdbus-1-3 \
    libnss3 \
    libnspr4 \
    libatk-bridge2.0-0 \
    libdrm2 \
    libxkbcommon0 \
    libatspi2.0-0 \
    libcups2 \
    libxshmfence1 \
    libgbm1 \
    fonts-noto-color-emoji \
    fonts-noto-cjk \
    fonts-freefont-ttf \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/

# 2. 安装 Node.js 22 LTS
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/

# 3. 安装 agent-browser 及 MCP Server，下载 Chrome (系统依赖已在步骤1安装)
RUN npm install -g agent-browser @rabbitai-lab/agent-browser-mcp \
    && agent-browser install

# 4. 创建 sandbox 用户，将 Chrome 缓存从 root 复制到 sandbox 家目录
RUN groupadd -r sandbox && useradd -r -g sandbox -G audio,video -s /bin/bash sandbox \
    && mkdir -p /home/sandbox /workspace \
    && cp -r /root/.agent-browser /home/sandbox/.agent-browser \
    && chown -R sandbox:sandbox /home/sandbox /workspace

# 5. 复制看门狗脚本
COPY --chmod=a+rx watchdog.sh /usr/local/bin/watchdog.sh

# 6. OpenSandbox bootstrap.sh 会读取 BOOTSTRAP_CMD 环境变量并优先执行
# K8s command 会覆盖镜像 CMD，但 ENV 仍然保留在容器内
ENV BOOTSTRAP_CMD="watchdog.sh & tail -f /dev/null"

# 暴露端口
# 12345 - Dashboard Web UI (内部端口 4848, socat 转发到 0.0.0.0:12345)
# 9222 - Chrome DevTools Protocol (CDP)
# 12346 - WebSocket Streaming
# 12347 - MCP Server
EXPOSE 12345 9222 12346 12347

WORKDIR /workspace
USER sandbox

CMD ["/bin/bash", "-c", "watchdog.sh & tail -f /dev/null"]
