#!/bin/bash

# ========================
# MySQL数据库备份脚本
# 支持：完整备份、差异备份、增量备份
# 策略：
# - 周一：完整备份
# - 周日：基于周一完整备份做差异备份
# - 其他日期：基于前一天做增量备份
# 保留策略：自动删除15天前的备份文件
# 邮件+钉钉通知
# ========================
#✅ 示例说明
#假设你周一做了完整备份，生成目录如下：
#/home/mysql_App/mysql_xtrabackup/2021-05-13/
#周二你要做增量备份，就要指定：
#innobackupex --incremental /home/mysql_App/mysql_xtrabackup --incremental-basedir=/home/mysql_App/mysql_xtrabackup/2021-05-13
#如果周一没有备份，那么就没有 /2021-05-13 这个目录，这时候做增量就会失败。
# ============ 配置参数 ============
BACKUP_DIR="/home/mysql_App/mysql_xtrabackup"
BACKUP_LOG_DIR="/home/mysql_App/mysql_xtrabackup_log"
SQL_USER="root"
SQL_PASSWORD="Hh.v0254"  # 生产环境建议使用低权限账户
RECIPIENTS="通知人邮箱号" # LIKE:y994189@163.com
NIU="牛牛报告"

# 创建目录（如不存在）
[ -d "$BACKUP_DIR" ] || mkdir -p "$BACKUP_DIR"
[ -d "$BACKUP_LOG_DIR" ] || mkdir -p "$BACKUP_LOG_DIR"

LOG_FILE="$BACKUP_LOG_DIR/mysql_backup.log"
DATE=$(date "+%Y-%m-%d %H:%M:%S")

# ============ 工具函数 ============

# 记录日志 + 发送通知
log_and_notify() {
    local msg="$1"
    local level="$2"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $level: $msg" >> "$LOG_FILE"

    # 调用钉钉通知函数（需自定义 sendDingMysql 函数）
    if [[ "$level" == "ERROR" ]]; then
        sendDingMysql "$NIU:$(date '+%Y-%m-%d %H:%M') 【失败】$msg"
    elif [[ "$level" == "INFO" ]]; then
        sendDingMysql "$NIU:$(date '+%Y-%m-%d %H:%M') 【成功】$msg"
    fi

    # 邮件通知（可选）
    echo "$DATE $msg" | mail -s "MySQL数据库备份状态" "$RECIPIENTS"
}

# 执行 xtrabackup 命令
do_backup() {
    local type="$1"
    local base_dir="$2"
    local cmd="innobackupex --user=${SQL_USER} --password='${SQL_PASSWORD}'"

    if [[ "$type" == "full" ]]; then
        $cmd "$BACKUP_DIR"
    elif [[ "$type" == "diff" ]]; then
        $cmd --incremental "$BACKUP_DIR" --incremental-basedir="$base_dir"
    elif [[ "$type" == "incr" ]]; then
        $cmd --incremental "$BACKUP_DIR" --incremental-basedir="$base_dir"
    else
        log_and_notify "未知备份类型: $type" "ERROR"
        return 1
    fi

    if [ $? -eq 0 ]; then
        log_and_notify "MySQL $type 备份成功" "INFO"
        return 0
    else
        log_and_notify "MySQL $type 备份失败" "ERROR"
        return 1
    fi
}

# 查找最近一次存在的备份目录
find_last_backup() {
    local target_date="$1"
    local dir="$BACKUP_DIR"
    local found=$(find "$dir" -maxdepth 1 -type d -name "$target_date" | sort | tail -n1)
    echo "$found"
}

# 删除超过15天的备份
cleanup_old_backups() {
    find "$BACKUP_DIR" -type d -mtime +15 -exec rm -rf {} \; >> "$LOG_FILE" 2>&1
    log_and_notify "已清理15天前的备份文件" "INFO"
}


WEEK_DAY=$(date +%w)

case "$WEEK_DAY" in
    1)  # 周一：完整备份
        log_and_notify "开始执行完整备份..." "INFO"
        do_backup "full"
        ;;
    7)  # 周日：差异备份，基于周一完整备份
        FULL_BACK_DATE=$(date -d '-6 day' +%Y-%m-%d)
        FULL_BACK_DIR=$(find_last_backup "$FULL_BACK_DATE")
        if [[ -d "$FULL_BACK_DIR" ]]; then
            log_and_notify "开始执行差异备份，基于完整备份目录: $FULL_BACK_DIR" "INFO"
            do_backup "diff" "$FULL_BACK_DIR"
        else
            log_and_notify "未找到完整备份目录: $FULL_BACK_DATE，跳过差异备份" "ERROR"
        fi
        ;;
    *)
        # 增量备份，基于前一天
        YESTERDAY=$(date -d '-1 day' +%Y-%m-%d)
        LAST_BACK_DIR=$(find_last_backup "$YESTERDAY")
        if [[ -d "$LAST_BACK_DIR" ]]; then
            log_and_notify "开始执行增量备份，基于目录: $LAST_BACK_DIR" "INFO"
            do_backup "incr" "$LAST_BACK_DIR"
        else
            log_and_notify "未找到前一天备份目录: $YESTERDAY，跳过增量备份" "ERROR"
        fi
        ;;
esac

cleanup_old_backups
