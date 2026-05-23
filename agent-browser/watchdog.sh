#!/bin/bash
# agent-browser 服务看门狗
# 确保dashboard和mcp服务始终运行
# Stream 依赖浏览器会话，由用户按需手动启用

DASHBOARD_PORT=12345
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
log "监控端口: Dashboard=${DASHBOARD_PORT}, MCP=${MCP_PORT}"
log "注意: Stream (12346) 依赖浏览器会话，由用户按需手动启用"
start_dashboard
start_mcp

# 主循环
while true; do
    start_dashboard
    start_mcp
    sleep $CHECK_INTERVAL
done
