#!/usr/bin/env bash

base_dir="/home/youxihu"  # 日志存储路径
cpu_used=${1:-80}  # 默认 CPU 目标使用率 80%
mem_used=80  # 目标内存使用率 80%

mkdir -p "$base_dir"

# 获取当前 CPU 使用率
cpu_using=$(top -bn2 | grep "Cpu(s)" | tail -1 | awk '{print $2}' | awk -F '.' '{print $1}')

# 获取当前可用内存和总内存
mem_info=$(free -m | awk '/Mem:/ {print $2, $3}')
total_mem=$(echo "$mem_info" | awk '{print $1}')
used_mem=$(echo "$mem_info" | awk '{print $2}')
mem_target=$(( total_mem * mem_used / 100 ))

# 如果 CPU 目标使用率低于当前使用率，则不执行
if [[ "$cpu_used" -le "$cpu_using" ]]; then
  echo "当前 CPU 使用率已达 ${cpu_using}%，无需增加负载"
else
  # 计算 CPU 线程数
  cpu_proc=$(grep -c 'processor' /proc/cpuinfo)

  # 计算需要增加的线程数量
  cpu_using_count=$(( cpu_proc * cpu_using / 100 ))
  cpu_used_count=$(( cpu_proc * cpu_used / 100 ))
  cpu_num=$(( cpu_used_count - cpu_using_count ))

  > "${base_dir}/kill_cpu_up.log"

  # 创建 CPU 负载
  for i in $(seq "$cpu_num"); do
    ( while true; do :; done ) &  # 死循环消耗 CPU
    echo "kill $!" >> "${base_dir}/kill_cpu_up.log"
  done

  echo "已增加 ${cpu_num} 个 CPU 线程"
fi

# 创建内存占用进程
if [[ "$used_mem" -lt "$mem_target" ]]; then
  mem_fill_size=$(( mem_target - used_mem ))
  echo "当前内存使用 ${used_mem}MB，目标 ${mem_target}MB，占用 ${mem_fill_size}MB"

  # 用大数组占满内存
  stress_mem=$(python3 -c "print(' ' * (1024 * 1024 * $mem_fill_size))")

  echo "内存占用进程创建完成"
else
  echo "当前内存已达 ${used_mem}MB，无需增加负载"
fi

