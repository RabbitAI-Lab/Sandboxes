FROM node:22-bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash ca-certificates curl git && \
    rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://releases.rivet.dev/sandbox-agent/0.4.x/install.sh | sh && \
    sandbox-agent install-agent --all

RUN useradd -m -s /bin/bash sandbox
USER sandbox
WORKDIR /home/sandbox

# OpenSandbox 覆盖启动命令时，bootstrap.sh 会读取此 ENV 拉起 sandbox-agent
ENV BOOTSTRAP_CMD="sandbox-agent server --host 0.0.0.0 --port 2468 --cors-allow-origin http://localhost:5173 --cors-allow-origin http://localhost:5174 --cors-allow-origin http://localhost:5175 --cors-allow-origin https://rabbitai-lab.com --cors-allow-origin http://*.sandbox.rabbitai-lab.com --cors-allow-origin http://*.sandbox.localhost"

EXPOSE 2468
ENTRYPOINT ["sandbox-agent"]
CMD ["server", "--host", "0.0.0.0", "--port", "2468", "--cors-allow-origin", "http://localhost:5173", "--cors-allow-origin", "http://localhost:5174", "--cors-allow-origin", "http://localhost:5175", "--cors-allow-origin", "https://rabbitai-lab.com", "--cors-allow-origin", "https://*.sandbox.rabbitai-lab.com", "--cors-allow-origin", "http://*.sandbox.localhost"]
