#!/bin/bash
set -e

# 输出时间戳的日志函数
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

# 检查必要的环境变量
if [ -z "${APP_DIR}" ]; then
    log "错误: 未设置 APP_DIR 环境变量"
    exit 1
fi

# 显示环境变量
log "显示当前环境变量："
env

# 检查并创建 heapdump 目录
HEAPDUMP_DIR="${APP_DIR}/heapdump"
if [ ! -d "$HEAPDUMP_DIR" ]; then
    log "创建 heapdump 目录: $HEAPDUMP_DIR"
    mkdir -p "$HEAPDUMP_DIR"
fi

# 切换到应用目录
log "切换到应用目录: ${APP_DIR}"
cd "${APP_DIR}" || exit 1

# 检查 JAR 文件是否存在
JAR_COUNT=$(ls -1 *.jar 2>/dev/null | wc -l)
if [ "$JAR_COUNT" -eq 0 ]; then
    log "错误: 在 ${APP_DIR} 中未找到 JAR 文件"
    exit 1
elif [ "$JAR_COUNT" -gt 1 ]; then
    log "警告: 发现多个 JAR 文件，将使用第一个"
fi

# 检查配置文件
CONFIG_FILE="${APP_DIR}/config/application.yml"
if [ ! -f "$CONFIG_FILE" ]; then
    log "错误: 配置文件不存在: $CONFIG_FILE"
    exit 1
fi

# 设置默认的 JVM 配置
if [ -z "${WVP_JVM_CONFIG}" ]; then
    WVP_JVM_CONFIG="-Xmx1g -Xms1g"
    log "未设置 WVP_JVM_CONFIG，使用默认值: ${WVP_JVM_CONFIG}"
fi

# 启动应用
log "正在启动应用..."
exec java ${WVP_JVM_CONFIG} \
    -XX:+HeapDumpOnOutOfMemoryError \
    -XX:HeapDumpPath="${HEAPDUMP_DIR}" \
    -jar *.jar \
    --spring.config.location="${CONFIG_FILE}" \
    --media.record-assist-port=18081 \
    ${WVP_CONFIG}