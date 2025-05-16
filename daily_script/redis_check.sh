#!/bin/bash

# Redis 配置
REDIS_HOST="127.0.0.1"
REDIS_PORT=6379
REDIS_PASSWORD="P@ssword1"

# 函数：检查 Redis 是否运行在 Docker 容器中
function is_redis_in_docker() {
    # 尝试找出运行中的 Redis 容器名
    container=$(docker ps -f "name=redis" --format "{{.Names}}" 2>/dev/null | head -n1)
    if [[ -n "$container" ]]; then
        echo "$container"
        return 0
    else
        return 1
    fi
}

# 函数：通过 docker exec 执行 Redis 命令
function check_redis_in_docker() {
    local container="$1"
    echo "Redis detected in Docker container: $container"

    info=$(docker exec "$container" redis-cli -a "$REDIS_PASSWORD" INFO 2>/dev/null)
    if [[ $? -ne 0 ]]; then
        echo "Error: Failed to get Redis INFO from container $container"
        return 1
    fi

    output_redis_info "$info"
}

# 函数：检查主机上的 Redis
function check_redis_on_host() {
    if ! command -v redis-cli &> /dev/null; then
        echo "Error: redis-cli not found on host"
        return 1
    fi

    if [ -z "$REDIS_PASSWORD" ]; then
        info=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" INFO 2>/dev/null)
    else
        info=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" -a "$REDIS_PASSWORD" INFO 2>/dev/null)
    fi

    if [[ $? -ne 0 ]]; then
        echo "Error: Failed to connect to Redis on host"
        return 1
    fi

    output_redis_info "$info"
}

# 函数：输出 Redis 状态信息
function output_redis_info() {
    local info="$1"

    echo "=== Redis Status ==="
    echo "Memory Used: $(echo "$info" | grep 'used_memory_human' | cut -d':' -f2)"
    echo "Total Connections Received: $(echo "$info" | grep 'total_connections_received' | cut -d':' -f2)"
    echo "Currently Connected Clients: $(echo "$info" | grep 'connected_clients' | cut -d':' -f2)"

    keys=$(echo "$info" | grep 'keyspace' | awk '{print $2}' | cut -d',' -f1)
    echo "Total Keys: ${keys:-0}"

    role=$(echo "$info" | grep 'role' | cut -d':' -f2)
    echo "Role: $role"

    if [[ "$role" == "master" ]]; then
        slaves=$(echo "$info" | grep 'connected_slaves' | cut -d':' -f2)
        echo "Connected Slaves: $slaves"
    elif [[ "$role" == "slave" ]]; then
        master_host=$(echo "$info" | grep 'master_host' | cut -d':' -f2)
        master_port=$(echo "$info" | grep 'master_port' | cut -d':' -f2)
        echo "Connected to Master: $master_host:$master_port"
    fi
}

echo "Detecting Redis deployment type..."

if container=$(is_redis_in_docker); then
    check_redis_in_docker "$container"
else
    echo "No Redis container found, checking Redis on host..."
    check_redis_on_host
fi