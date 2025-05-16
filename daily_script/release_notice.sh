#!/bin/bash

# 钉钉 Webhook 地址
DINGTALK_WEBHOOK_URL="https://oapi.dingtalk.com/robot/send?access_token=eac0b668fa146d2484fb94669b8ce7c4d5d0a15286383d64aba06f8ebe8790b1 "

# 项目路径定义
BACKEND_DIR="/home/jenkins/build/bbx-saas"
FRONTEND_DIR1="/home/jenkins/build/galaxy-pc-nuxt3"
FRONTEND_DIR2="/home/jenkins/build/bbx-aiwrite-vue3"

# 获取当前时间信息
current_weekday=$(date +%u)     # 星期几（1-7）
current_day=$(date +%d)         # 当前天数
current_year_month=$(date +%y%m)
week_number=$(date +%V)         # 当年第几周
month_number=$(date +%-m)        # 当月第几月不包含前置数0 如果是date +%m 则包含0

# 获取本月最后一天
last_day_of_month=$(cal $(date +%m) $(date +%Y) | awk 'NF {DAYS = $NF}; END {print DAYS}')

# 判断是否是周五或月末
is_friday=0
is_last_day=0

if [[ "$current_weekday" -eq 5 ]]; then
    is_friday=1
fi

if [[ "$current_day" -eq "$last_day_of_month" ]]; then
    is_last_day=1
fi

# 发送钉钉消息函数
function send_dingtalk_message() {
    local title="$1"
    local content="$2"

    JSON_MSG='{"msgtype": "markdown","markdown": {"title": "'"$title"'","text": "'"$content"'\n\n> 此通知由自动化运维系统发送 @所有人"}}'

    response=$(echo "$JSON_MSG" | curl -s -H "Content-Type: application/json" -d @- "$DINGTALK_WEBHOOK_URL")

    if [[ "$response" == *"errcode\":0"* ]]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') 消息推送成功"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') 消息推送失败: $response"
    fi
}

# 更新 Git 仓库（进入目录并拉取最新代码）
function update_git_repo() {
    local project_dir="$1"
    cd "$project_dir" || { echo "❌ 无法进入目录 $project_dir"; return 1; }

    echo "🔄 正在更新项目: $(basename "$project_dir")"
    git fetch --quiet
    git reset --quiet
    git pull origin main --quiet || git pull origin master --quiet
}

# 获取构建次数函数
function get_build_stats_this_week() {
    local project_dir="$1"
    cd "$project_dir" || { echo "❌ 无法进入目录 $project_dir"; exit 1; }

    all=$(git log --since="last week" --grep='build' --oneline | wc -l)
    prod=$(git log --since="last week" --grep='buildonline' --oneline | wc -l)
    test=$((all - prod))

    echo "$all $prod $test"
}

# 获取本月构建次数
function get_build_stats_this_month() {
    local project_dir="$1"
    local since_date=$(date +%Y-%m-01)

    cd "$project_dir" || { echo "❌ 无法进入目录 $project_dir"; exit 1; }

    all=$(git log --since="$since_date" --grep='build' --oneline | wc -l)
    prod=$(git log --since="$since_date" --grep='buildonline' --oneline | wc -l)
    test=$((all - prod))

    echo "$all $prod $test"
}

# 获取开发者提交次数函数
function get_commit_stats_by_author() {
    local project_dir="$1"
    local since_date="$2"

    cd "$project_dir" || { echo "❌ 无法进入目录 $project_dir"; exit 1; }

    git log --since="$since_date" --format='%aN' | sort | uniq -c | awk '{print $2 " " $1}'
}

# 构建周报内容
function week_summary() {
    echo "🔄 更新所有项目代码..."
    update_git_repo "$BACKEND_DIR"
    update_git_repo "$FRONTEND_DIR1"
    update_git_repo "$FRONTEND_DIR2"

    echo "📊 开始统计构建数据..."

    # 获取后端构建次数
    backend_stats=($(get_build_stats_this_week "$BACKEND_DIR"))
    backend_all=${backend_stats[0]}
    backend_prod=${backend_stats[1]}
    backend_test=${backend_stats[2]}

    # 获取前端项目构建次数
    fe1_stats=($(get_build_stats_this_week "$FRONTEND_DIR1"))
    fe2_stats=($(get_build_stats_this_week "$FRONTEND_DIR2"))

    frontend_all=$((fe1_stats[0] + fe2_stats[0]))
    frontend_prod=$((fe1_stats[1] + fe2_stats[1]))
    frontend_test=$((frontend_all - frontend_prod))

    echo "👤 收集开发者提交数据..."

    # 收集所有开发者
    authors_backend=$(cd "$BACKEND_DIR" && git log --since="last week" --format='%aN' | sort | uniq)
    authors_fe1=$(cd "$FRONTEND_DIR1" && git log --since="last week" --format='%aN' | sort | uniq)
    authors_fe2=$(cd "$FRONTEND_DIR2" && git log --since="last week" --format='%aN' | sort | uniq)

    all_authors=$(echo -e "$authors_backend\n$authors_fe1\n$authors_fe2" | sort | uniq)

    declare -A author_commit_counts

    for author in $all_authors; do
        # 统一 Youxihu 的大小写
        normalized_author=$(echo "$author" | awk '{print tolower($0)}')
        if [[ "$author" == "Youxihu" ]]; then
            normalized_author="youxihu"
        fi

        count_backend=$(cd "$BACKEND_DIR" && git log --since="last week" --author="$author" --oneline | wc -l)
        count_fe1=$(cd "$FRONTEND_DIR1" && git log --since="last week" --author="$author" --oneline | wc -l)
        count_fe2=$(cd "$FRONTEND_DIR2" && git log --since="last week" --author="$author" --oneline | wc -l)
        total=$((count_backend + count_fe1 + count_fe2))
        ((author_commit_counts[$normalized_author]+=$total))
    done

    commit_table=""
    for author in "${!author_commit_counts[@]}"; do
        commit_table+="| ${author} | ${author_commit_counts[$author]} |\n"
    done

    message="### 事件通知:2025年第${week_number}周构建与代码统计"

    # 添加构建统计部分
    message+="\n#### 推送构建统计\n"
    message+="- 后端共推送了 **$backend_all** 次构建（调试：**$backend_test**，正式：**$backend_prod**）\n"
    message+="- 前端共推送了 **$frontend_all** 次构建（调试：**$frontend_test**，正式：**$frontend_prod**）\n\n"

    # 添加开发者提交次数部分
    message+="#### 开发者代码提交次数：\n"
    message+="| 开发者 | 提交次数 |\n"
    message+="|--------|----------|\n"
    message+="$commit_table"

    # 发送钉钉消息
    send_dingtalk_message "【CI/CD构建与开发者行为统计】" "$message"
}

# 构建月报内容
function month_summary() {
    current_month_start=$(date +%Y-%m-01)

    echo "🔄 更新所有项目代码..."
    update_git_repo "$BACKEND_DIR"
    update_git_repo "$FRONTEND_DIR1"
    update_git_repo "$FRONTEND_DIR2"

    echo "📊 开始统计构建数据..."

    # 获取后端构建次数
    backend_stats=($(get_build_stats_this_month "$BACKEND_DIR"))
    backend_all=${backend_stats[0]}
    backend_prod=${backend_stats[1]}
    backend_test=$((backend_all - backend_prod))

    # 获取前端项目构建次数
    fe1_stats=($(get_build_stats_this_month "$FRONTEND_DIR1"))
    fe2_stats=($(get_build_stats_this_month "$FRONTEND_DIR2"))

    frontend_all=$((fe1_stats[0] + fe2_stats[0]))
    frontend_prod=$((fe1_stats[1] + fe2_stats[1]))
    frontend_test=$((frontend_all - frontend_prod))

    echo "👤 收集开发者提交数据..."

    # 收集所有开发者
    authors_backend=$(cd "$BACKEND_DIR" && git log --since="$current_month_start" --format='%aN' | sort | uniq)
    authors_fe1=$(cd "$FRONTEND_DIR1" && git log --since="$current_month_start" --format='%aN' | sort | uniq)
    authors_fe2=$(cd "$FRONTEND_DIR2" && git log --since="$current_month_start" --format='%aN' | sort | uniq)

    all_authors=$(echo -e "$authors_backend\n$authors_fe1\n$authors_fe2" | sort | uniq)

    commit_table=""
    for author in $all_authors; do
        count_backend=$(cd "$BACKEND_DIR" && git log --since="$current_month_start" --author="$author" --oneline | wc -l)
        count_fe1=$(cd "$FRONTEND_DIR1" && git log --since="$current_month_start" --author="$author" --oneline | wc -l)
        count_fe2=$(cd "$FRONTEND_DIR2" && git log --since="$current_month_start" --author="$author" --oneline | wc -l)
        total=$((count_backend + count_fe1 + count_fe2))
        if (( total > 0 )); then
            commit_table+="| $author | $total |\n"
        fi
    done

    message="### 事件通知:2025年${month_number}月构建与代码统计"

    # 添加构建统计部分
    message+="\n#### 推送构建统计\n"
    message+="- 后端共推送了 **$backend_all** 次构建（调试：**$backend_test**，正式：**$backend_prod**）\n"
    message+="- 前端共推送了 **$frontend_all** 次构建（调试：**$frontend_test**，正式：**$frontend_prod**）\n\n"

    # 添加开发者提交次数部分
    message+="#### 开发者代码提交次数：\n"
    message+="| 开发者 | 提交次数 |\n"
    message+="|--------|----------|\n"
    message+="$commit_table"

    # 发送钉钉消息
    send_dingtalk_message "【CI/CD构建与开发者行为统计】" "$message"
}

# ========== 主流程 ============

if [[ "$is_last_day" -eq 1 ]]; then
    echo "📅 今天是本月最后一天，发送月报..."
    month_summary
elif [[ "$is_friday" -eq 1 ]]; then
    echo "📆 今天是周五，发送周报..."
    week_summary
else
    echo "ℹ️ 今天既不是周五也不是月末，不发送通知。"
fi