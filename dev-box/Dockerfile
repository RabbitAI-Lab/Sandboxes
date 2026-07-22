FROM ubuntu:24.04

# BuildKit 自动注入:amd64 / arm64
ARG TARGETARCH
ARG NODE_VERSION=24.18.0
ARG PNPM_VERSION=10.13.1
ARG MAVEN_VERSION=3.9.9
ARG GRADLE_VERSION=9.6.1
ARG GRADLE_LEGACY_VERSION=8.10
ARG TEMURIN_VERSION=26

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    TZ=Asia/Shanghai

# 1. 基础工具 + Python + 编译工具链 + 终端/网络调试/数据库客户端
#    (Ubuntu 上 bat/fd 的二进制名为 batcat/fdfind,软链为常用名)
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash ca-certificates curl wget gnupg git vim htop jq \
    net-tools iputils-ping dnsutils unzip zip xz-utils \
    build-essential python3 python3-pip python3-venv python3-dev \
    software-properties-common apt-transport-https \
    openssh-client sudo less nano tree \
    zsh fzf ripgrep fd-find bat tmux \
    netcat-openbsd traceroute lsof strace openssl socat \
    postgresql-client mysql-client redis-tools sqlite3 \
    && ln -s /usr/bin/batcat /usr/local/bin/bat \
    && ln -s /usr/bin/fdfind /usr/local/bin/fd \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/

# 2. GitHub CLI + Nginx + OpenJDK 8/21(一次 update,一层装完)
RUN mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | gpg --dearmor -o /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list \
    && add-apt-repository ppa:openjdk-r/ppa -y \
    && apt-get update \
    && apt-get install -y --no-install-recommends gh nginx openjdk-8-jdk openjdk-21-jdk \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/

# 3. Node.js(Node 官方包 amd64 名为 x64,arm64 名为 arm64)
RUN case "$TARGETARCH" in \
        amd64) NODE_ARCH=x64 ;; \
        arm64) NODE_ARCH=arm64 ;; \
        *) echo "不支持的架构: $TARGETARCH" && exit 1 ;; \
    esac \
    && curl -fSL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${NODE_ARCH}.tar.xz" -o /tmp/node.tar.xz \
    && mkdir -p /usr/local/lib/nodejs \
    && tar -xJf /tmp/node.tar.xz -C /usr/local/lib/nodejs \
    && ln -s "/usr/local/lib/nodejs/node-v${NODE_VERSION}-linux-${NODE_ARCH}" /usr/local/lib/nodejs/current \
    && rm /tmp/node.tar.xz
ENV NODE_HOME=/usr/local/lib/nodejs/current
ENV PATH=$NODE_HOME/bin:$PATH

# 4. pnpm(锁定版本)+ PM2 + Claude Code
#    不用 corepack:其缓存按用户隔离,sandbox 用户运行时会重新下载
RUN npm install -g pnpm@${PNPM_VERSION} pm2 @anthropic-ai/claude-code \
    && npm cache clean --force

# 5. Python 别名
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 1 \
    && update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 1

# 6. uv + browser-use CLI(基于系统 Python 3.12,工具和入口对所有用户可用)
#    用法见 https://docs.browser-use.com/open-source/browser-use-cli
ENV UV_TOOL_DIR=/opt/uv-tools \
    UV_TOOL_BIN_DIR=/usr/local/bin
RUN curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin INSTALLER_NO_MODIFY_PATH=1 sh \
    && uv tool install --python /usr/bin/python3 browser-use

# 7. Temurin JDK 26(最新 GA;Ubuntu 仓库没有,从 Adoptium 下载)
RUN case "$TARGETARCH" in \
        amd64) JDK_ARCH=x64 ;; \
        arm64) JDK_ARCH=aarch64 ;; \
        *) echo "不支持的架构: $TARGETARCH" && exit 1 ;; \
    esac \
    && curl -fSL "https://api.adoptium.net/v3/binary/latest/${TEMURIN_VERSION}/ga/linux/${JDK_ARCH}/jdk/hotspot/normal/eclipse" -o /tmp/jdk.tar.gz \
    && mkdir -p /usr/lib/jvm/temurin-${TEMURIN_VERSION} \
    && tar -xzf /tmp/jdk.tar.gz -C /usr/lib/jvm/temurin-${TEMURIN_VERSION} --strip-components=1 \
    && rm /tmp/jdk.tar.gz

# 8. 默认 JDK 21,配置三个版本切换
ENV JAVA_HOME=/usr/lib/jvm/java-21-openjdk-${TARGETARCH}
ENV PATH=$JAVA_HOME/bin:$PATH
RUN update-alternatives --install /usr/bin/java java /usr/lib/jvm/java-8-openjdk-${TARGETARCH}/bin/java 1 \
    && update-alternatives --install /usr/bin/java java /usr/lib/jvm/java-21-openjdk-${TARGETARCH}/bin/java 2 \
    && update-alternatives --install /usr/bin/java java /usr/lib/jvm/temurin-${TEMURIN_VERSION}/bin/java 3 \
    && update-alternatives --install /usr/bin/javac javac /usr/lib/jvm/java-8-openjdk-${TARGETARCH}/bin/javac 1 \
    && update-alternatives --install /usr/bin/javac javac /usr/lib/jvm/java-21-openjdk-${TARGETARCH}/bin/javac 2 \
    && update-alternatives --install /usr/bin/javac javac /usr/lib/jvm/temurin-${TEMURIN_VERSION}/bin/javac 3

# JDK 切换脚本(注意:脚本在子 shell 执行,JAVA_HOME 需按提示手动 export)
RUN <<EOF
cat > /usr/local/bin/jdk-switch <<'SCRIPT'
#!/bin/bash
case $1 in
  8)
    NEW_JAVA_HOME=/usr/lib/jvm/java-8-openjdk-${TARGETARCH}
    ;;
  21)
    NEW_JAVA_HOME=/usr/lib/jvm/java-21-openjdk-${TARGETARCH}
    ;;
  26)
    NEW_JAVA_HOME=/usr/lib/jvm/temurin-${TEMURIN_VERSION}
    ;;
  *)
    echo "Usage: jdk-switch [8|21|26]"
    exit 1
    ;;
esac
update-alternatives --set java  "\$NEW_JAVA_HOME/bin/java"
update-alternatives --set javac "\$NEW_JAVA_HOME/bin/javac"
echo "Switched to Java:"
java -version
echo "提示: 请在当前 shell 执行 export JAVA_HOME=\$NEW_JAVA_HOME"
SCRIPT
chmod +x /usr/local/bin/jdk-switch
EOF

# 9. Maven(dlcdn 只保留最新版,历史版本走 archive.apache.org)
RUN curl -fSL "https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz" -o /tmp/maven.tar.gz \
    && mkdir -p /opt/maven \
    && tar -xzf /tmp/maven.tar.gz -C /opt/maven --strip-components=1 \
    && rm /tmp/maven.tar.gz \
    && ln -s /opt/maven/bin/mvn /usr/local/bin/mvn
ENV MAVEN_HOME=/opt/maven
ENV PATH=$MAVEN_HOME/bin:$PATH

# 10. Gradle 双版本(8.10 兼容老项目,可跑在 JDK 8-22;9.x 支持 JDK 17-26)
#    默认 9.x;切换: sudo update-alternatives --config gradle
#    注意: 不设 GRADLE_HOME/PATH,启动脚本会沿 alternatives 软链自动定位,保证切换生效
RUN for v in ${GRADLE_LEGACY_VERSION} ${GRADLE_VERSION}; do \
        curl -fSL "https://services.gradle.org/distributions/gradle-${v}-bin.zip" -o /tmp/gradle-${v}.zip \
        && mkdir -p /opt/gradle/${v} \
        && unzip -q -d /opt/gradle/${v} /tmp/gradle-${v}.zip \
        && mv /opt/gradle/${v}/gradle-${v}/* /opt/gradle/${v}/ \
        && rm -rf /opt/gradle/${v}/gradle-${v} /tmp/gradle-${v}.zip; \
    done \
    && update-alternatives --install /usr/local/bin/gradle gradle /opt/gradle/${GRADLE_LEGACY_VERSION}/bin/gradle 1 \
    && update-alternatives --install /usr/local/bin/gradle gradle /opt/gradle/${GRADLE_VERSION}/bin/gradle 2

# 11. 创建非 root 用户(默认 zsh,免密 sudo 方便开发调试)
RUN groupadd -r sandbox && useradd -r -g sandbox -s /bin/zsh -m sandbox \
    && mkdir -p /workspace \
    && chown -R sandbox:sandbox /home/sandbox /workspace \
    && echo 'sandbox ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/sandbox

# 3000/8000/8080 - 常用开发服务端口(80/443 为特权端口,sandbox 用户无法绑定,请用高端口)
EXPOSE 3000 8000 8080

WORKDIR /workspace
USER sandbox

CMD ["/bin/bash", "-c", "tail -f /dev/null"]
