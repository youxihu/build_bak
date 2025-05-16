#!/bin/bash

# 获取 CPU 核心数
cores=$(nproc)

# 获取系统1、5、15分钟负载
read one five fifteen rest < /proc/loadavg

# 计算阈值（整数部分）
threshold=$(echo "0.7 * $cores" | bc | awk -F. '{print $1}')

# 使用 bc 比较浮点数
function is_less_than {
    local value=$1
    local limit=$2
    result=$(echo "$value < $limit" | bc)
    return $result
}

is_less_than "$one" "$threshold"
r1=$?

is_less_than "$five" "$threshold"
r2=$?

is_less_than "$fifteen" "$threshold"
r3=$?

if [ $r1 -eq 1 ] && [ $r2 -eq 1 ] && [ $r3 -eq 1 ]; then
  echo "系统负载正常, 1/5/15分钟负载为: $one / $five / $fifteen"
else
  echo "系统负载过高, 1/5/15分钟负载为: $one / $five / $fifteen"
fi