#!/bin/bash
# agent-browser 服务看门狗
# 确保dashboard、stream、mcp三个服务始终运行

DASHBOARD_PORT=12345
STREAM_PORT=12346
MCP_PORT=12347
CHECK_INTERVAL=10

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [watchdog] $1"
}

check_port() {
    local port=$1
    curl -s -o /dev/null --connect-timeout 2 "http://localhost:${port}" 2>/dev/null
    return $?
}

start_dashboard() {
    if ! check_port $DASHBOARD_PORT; then
        log "Dashboard (port ${DASHBOARD_PORT}) 未运行，正在拉起..."
        nohup agent-browser dashboard start --port $DASHBOARD_PORT > /tmp/dashboard.log 2>&1 &
        sleep 2
        if check_port $DASHBOARD_PORT; then
            log "Dashboard 已成功拉起"
        else
            log "WARNING: Dashboard 拉起失败，下次循环重试"
        fi
    fi
}

start_stream() {
    if ! check_port $STREAM_PORT; then
        log "Stream (port ${STREAM_PORT}) 未运行，正在拉起..."
        nohup agent-browser stream enable --port $STREAM_PORT > /tmp/stream.log 2>&1 &
        sleep 2
        if check_port $STREAM_PORT; then
            log "Stream 已成功拉起"
        else
            log "WARNING: Stream 拉起失败，下次循环重试"
        fi
    fi
}

start_mcp() {
    if ! check_port $MCP_PORT; then
        log "MCP Server (port ${MCP_PORT}) 未运行，正在拉起..."
        nohup agent-browser-mcp --port $MCP_PORT > /tmp/mcp.log 2>&1 &
        sleep 2
        if check_port $MCP_PORT; then
            log "MCP Server 已成功拉起"
        else
            log "WARNING: MCP Server 拉起失败，下次循环重试"
        fi
    fi
}

# 初始启动
log "启动 agent-browser 看门狗..."
log "监控端口: Dashboard=${DASHBOARD_PORT}, Stream=${STREAM_PORT}, MCP=${MCP_PORT}"
start_dashboard
start_stream
start_mcp

# 主循环
while true; do
    start_dashboard
    start_stream
    start_mcp
    sleep $CHECK_INTERVAL
done
