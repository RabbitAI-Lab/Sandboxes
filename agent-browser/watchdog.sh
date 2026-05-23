#!/bin/bash
# agent-browser 服务看门狗
# 确保dashboard和mcp服务始终运行
# Stream 依赖浏览器会话，由用户按需手动启用
#
# 注意: agent-browser dashboard 默认绑定 127.0.0.1 (仅容器内部可访问)
# 因此 Dashboard 在内部端口 4848 启动，通过 socat 转发到 0.0.0.0:12345 供外部访问

DASHBOARD_INTERNAL_PORT=4848
DASHBOARD_EXTERNAL_PORT=12345
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

check_socat() {
    # 检查 socat 转发进程是否存活
    pgrep -f "socat.*TCP-LISTEN:${DASHBOARD_EXTERNAL_PORT}" > /dev/null 2>&1
    return $?
}

start_dashboard() {
    if ! check_port $DASHBOARD_INTERNAL_PORT; then
        log "Dashboard (内部端口 ${DASHBOARD_INTERNAL_PORT}) 未运行，正在拉起..."
        nohup agent-browser dashboard start --port $DASHBOARD_INTERNAL_PORT > /tmp/dashboard.log 2>&1 &
        sleep 2
        if check_port $DASHBOARD_INTERNAL_PORT; then
            log "Dashboard 已成功拉起 (内部端口 ${DASHBOARD_INTERNAL_PORT})"
        else
            log "WARNING: Dashboard 拉起失败，下次循环重试"
            return 1
        fi
    fi

    # 确保 socat 转发存活
    if ! check_socat; then
        log "socat 转发 (0.0.0.0:${DASHBOARD_EXTERNAL_PORT} -> 127.0.0.1:${DASHBOARD_INTERNAL_PORT}) 未运行，正在启动..."
        nohup socat TCP-LISTEN:${DASHBOARD_EXTERNAL_PORT},fork,reuseaddr,bind=0.0.0.0 TCP:127.0.0.1:${DASHBOARD_INTERNAL_PORT} > /tmp/socat-dashboard.log 2>&1 &
        sleep 1
        if check_socat; then
            log "socat 转发已启动，外部端口 ${DASHBOARD_EXTERNAL_PORT} 可访问"
        else
            log "WARNING: socat 转发启动失败，下次循环重试"
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
log "监控: Dashboard=0.0.0.0:${DASHBOARD_EXTERNAL_PORT}->127.0.0.1:${DASHBOARD_INTERNAL_PORT}, MCP=${MCP_PORT}"
log "注意: Stream (12346) 依赖浏览器会话，由用户按需手动启用"
start_dashboard
start_mcp

# 主循环
while true; do
    start_dashboard
    start_mcp
    sleep $CHECK_INTERVAL
done
