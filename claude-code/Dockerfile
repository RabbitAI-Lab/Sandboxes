# 基础镜像
FROM ubuntu:24.04

# 避免交互式提示
ENV DEBIAN_FRONTEND=noninteractive

# 1. 安装常用开发工具
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    vim \
    curl \
    wget \
    jq \
    build-essential \
    ca-certificates \
    gnupg \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/

# 2. 安装 Node.js 22 LTS（用于 JS/TS 项目运行）
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/

# 3. 安装 Claude Code（原生安装，官方推荐）
RUN curl -fsSL https://claude.ai/install.sh | bash

# 4. 安装 sandbox-agent
RUN curl -fsSL https://releases.rivet.dev/sandbox-agent/0.4.x/install.sh | sh \
    && sandbox-agent install-agent claude \
    && sandbox-agent install-agent opencode \
    && sandbox-agent install-agent codex \
    && sandbox-agent install-agent amp \
    && sandbox-agent install-agent pi

# 5. 创建非 root 用户和 workspace 目录（遵循 OpenSandbox 约定）
RUN groupadd -r sandbox && useradd -r -g sandbox -s /bin/bash sandbox \
    && mkdir -p /home/sandbox /workspace \
    && cp -rL /root/.local /home/sandbox/.local \
    && chown -R sandbox:sandbox /home/sandbox /workspace

# 6. 复制看门狗脚本
COPY --chmod=a+rx watchdog.sh /usr/local/bin/watchdog.sh

# 7. OpenSandbox bootstrap 兼容：K8s 环境通过 BOOTSTRAP_CMD 自动拉起看门狗
ENV BOOTSTRAP_CMD="watchdog.sh & tail -f /dev/null"

# 8. 暴露 sandbox-agent daemon 端口
EXPOSE 2468

# 工作目录
WORKDIR /workspace

# 切换为非 root 用户
USER sandbox

# 环境变量说明：
# ANTHROPIC_API_KEY - 用于 API Key 认证（运行时传入）
# 浏览器交互登录 - 运行 claude 命令后通过浏览器认证
ENV PATH="/home/sandbox/.local/bin:${PATH}"

# 默认入口：启动看门狗监控 sandbox-agent daemon (port 2468)，容器保持存活
CMD ["/bin/bash", "-c", "watchdog.sh & tail -f /dev/null"]
