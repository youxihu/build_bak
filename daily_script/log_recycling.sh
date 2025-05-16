#!/bin/bash

# 日志路径与文件定义
LOGPATH="/workserver/work-local/nginx/nginx-logs/bbx_prod"
ACCESS_LOG="online.biaobiaoxing.com.log"
ERROR_LOG="online.biaobiaoxing.com.error.log"

# 当前时间格式用于打包命名（不含斜杠）
date=$(date "+%Y-%m-%d-%H-%M")

# 切换到日志目录
cd "$LOGPATH" || { echo "无法进入目录 $LOGPATH"; exit 1; }

# 获取最近30天的日期正则表达式
function get_date_regex() {
    for i in {0..30}; do
        date -d "$i days ago" "+%d/%b/%Y"
    done | xargs | sed 's/ /|/g'
}

# 打包指定的日志文件
function backup_log_file() {
    local log_file="$1"
    local prefix="$2"
    if [[ -f "$log_file" ]]; then
        tar czf "${date}-${prefix}-log.tar.gz" "$log_file"
    fi
}

# 过滤并更新日志内容（保留最近30天）
function update_log_file() {
    local log_file="$1"
    local regex="$2"
    if [[ -f "$log_file" ]]; then
        grep -E "$regex" "$log_file" > "${log_file}.tmp"
        rm -f "$log_file"
        mv "${log_file}.tmp" "$log_file"
    fi
}

DATE_REGEX=$(get_date_regex)

# 备份原始日志
backup_log_file "$ACCESS_LOG" "access"
backup_log_file "$ERROR_LOG" "error"

# 更新日志内容（保留最近30天）
update_log_file "$ACCESS_LOG" "$DATE_REGEX"
update_log_file "$ERROR_LOG" "$DATE_REGEX"

# 删除3天前的旧备份
find . -name "*.tar.gz" -type f -mtime +3 -exec rm {} \;