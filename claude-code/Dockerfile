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

# 4. 创建非 root 用户和 workspace 目录（遵循 OpenSandbox 约定）
RUN groupadd -r sandbox && useradd -r -g sandbox -s /bin/bash sandbox \
    && mkdir -p /home/sandbox /workspace \
    && cp -r /root/.local /home/sandbox/.local \
    && chown -R sandbox:sandbox /home/sandbox /workspace

# 工作目录
WORKDIR /workspace

# 切换为非 root 用户
USER sandbox

# 环境变量说明：
# ANTHROPIC_API_KEY - 用于 API Key 认证（运行时传入）
# 浏览器交互登录 - 运行 claude 命令后通过浏览器认证
ENV PATH="/home/sandbox/.local/bin:${PATH}"

# 默认入口
CMD ["bash"]
