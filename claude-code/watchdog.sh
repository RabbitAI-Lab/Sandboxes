#!/bin/bash
# sandbox-agent 服务看门狗
# 确保 sandbox-agent daemon 始终运行在端口 2468

AGENT_PORT=2468
CHECK_INTERVAL=10

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [watchdog] $1"
}

check_port() {
    local port=$1
    curl -s -o /dev/null --connect-timeout 2 "http://localhost:${port}" 2>/dev/null
    return $?
}

start_sandbox_agent() {
    if ! check_port $AGENT_PORT; then
        log "sandbox-agent (port ${AGENT_PORT}) 未运行，正在拉起..."
        nohup sandbox-agent daemon start --host 0.0.0.0 --port $AGENT_PORT > /tmp/sandbox-agent.log 2>&1 &
        sleep 2
        if check_port $AGENT_PORT; then
            log "sandbox-agent 已成功拉起 (0.0.0.0:${AGENT_PORT})"
        else
            log "WARNING: sandbox-agent 拉起失败，下次循环重试"
        fi
    fi
}

# 初始启动
log "启动 sandbox-agent 看门狗..."
log "监控: sandbox-agent daemon = 0.0.0.0:${AGENT_PORT}"
start_sandbox_agent

# 主循环
while true; do
    start_sandbox_agent
    sleep $CHECK_INTERVAL
done
