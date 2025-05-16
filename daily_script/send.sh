#!/bin/bash

# 加载相关函数
source /home/sys_bash_send/sendIP.sh
source /home/sys_bash_send/send_rootCapacity.sh
source /home/sys_bash_send/sendTom.sh

# 设置文件路径
ip_file="/home/youxihu/alarm/old_ip.txt"

check_and_update_ip() {
    # 检查文件是否存在，如果不存在则创建
    [ ! -e "$ip_file" ] && touch "$ip_file"

    # 获取旧IP地址
    old_ip=$(<"$ip_file")

    # 获取新IP地址，支持重试
    max_retries=3  # 最大重试次数
    retry_count=0
    new_ip=""

    while [ -z "$new_ip" ] && [ $retry_count -lt $max_retries ]; do
        new_ip=$(curl -s icanhazip.com)
        if [ -z "$new_ip" ]; then
            retry_count=$((retry_count + 1))
            echo "获取IP失败，正在重试 ($retry_count/$max_retries)..."
            sleep 2  # 每次重试间隔2秒
        fi
    done

    # 如果最终仍然获取不到IP，记录错误并退出
    if [ -z "$new_ip" ]; then
        echo "错误：无法获取IP地址，请检查网络连接或服务是否可用"
        sendDingIP "### **告警通知: $IPIP**\n#### 状态: IP获取失败\n- 错误: 无法获取IP地址\n- 执行时间: $(date +'%Y-%m-%d %H:%M:%S')\n- 备注: 请检查网络连接或服务是否可用\n"
        return 1
    fi

    # 如果IP发生变化，更新文件并发送通知
    if [ "$old_ip" != "$new_ip" ]; then
        echo "$new_ip" > "$ip_file"
        sendDingIP "### **告警通知: $IPIP**\n#### 状态: 待处理\n- IP地址: $new_ip\n- 执行时间: $(date +'%Y-%m-%d %H:%M:%S')\n- 备注: 请及时修改安全组确保服务正常使用\n"
    else
        echo "IP无变化"
    fi
}

# 函数：检查根分区使用率
check_root_capacity() {
    gen_directory=$(df -Th | awk '/\/dev\/mapper\/centos-root/ {print $6}' | tr -d '%')
    if [ "$gen_directory" -ge 80 ]; then
        sendDingcapacity "### **告警通知: 254根分区已满**\n#### 状态: 待处理\n- 使用率: $gen_directory%\n- 执行时间: $(date +'%Y-%m-%d %H:%M:%S')\n- 备注: 请及时登录254服务器处理异常\n---\n$Long"
    else
        echo "根分区容量正常"
    fi
}

# 函数：检查Tomcat进程
check_tomcat_process() {
    if ps -aux | grep -q '[t]omcat'; then
        echo "Tomecat正常运行"
    else
        sendDingPower "### **告警通知: Jenkins已宕机**\n#### 状态: 待处理\n- 原因: 机房断电\n- 执行时间: $(date +'%Y-%m-%d %H:%M:%S')\n- 备注: 请及时检查并重启服务\n---\n$LongTom"
    fi
}

# 调用各个功能函数
check_and_update_ip
check_root_capacity
check_tomcat_process