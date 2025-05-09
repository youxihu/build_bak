#!/bin/bash

# 工作目录
work_dir="/home/jenkins/build"
build_dir="$work_dir/galaxy-pc-nuxt3/build/beta"
execute_dir="/home/jenkins/execute"

# 加载告警发送脚本和本地变量
source "/home/sys_bash_send/send_pc.sh"
source "$execute_dir/node-local-info.sh"

# 切换到工作目录
cd "$work_dir/galaxy-pc-nuxt3" && echo "切换工作目录成功" || { echo "切换工作目录失败"; exit 1; }

# 拉取最新代码
fetch_and_build() {
    git stash || { echo "Git Stash 操作失败"; exit 1; }

    if ! git pull origin master; then
        sendDingMessage "### **告警通知: 代码拉取失败**\n#### 状态：待处理\n- 提交人: $presenter\n- 原因: 代码拉取失败，请检查网络或权限"
        exit 1
    fi
    echo "代码拉取成功"
}

# 写入构建所需变量
write_env_vars() {
    echo "写入构建所需变量..."
    cat <<EOF >"$build_dir/load-env.sh"
export commit_message="$commit_message"
export build="$build"
export environ="$environ"
export version="$version"
export write_time="$(date +'%Y-%m-%d %H:%M:%S')"
export presenter="$presenter"
EOF
}

# 构建镜像
build_image() {
    local app_dir=$1

    cd "$app_dir" || { echo "无法切换到应用目录: $app_dir"; exit 1; }

    if ! docker build -t "$repo_addr/$environ-galaxy-pc-nuxt3:$version" .; then
        echo "镜像构建失败，请检查 Dockerfile 和构建环境"
        exit 1
    fi
}

deploy_app() {
    local host_port="54300"
    if [[ "$environ" == "rc" ]]; then
        host_port="54310"
    fi

    if ! echo "$repo_passwd" | docker login -u "$repo_user" --password-stdin "$repo_addr"; then
        echo "登录镜像仓库失败，请检查用户名和密码"
        exit 1
    fi

    old_server=$(docker ps -a | grep "$environ-galaxy-pc-nuxt3" | awk '{print $1}')
    if [[ -n "$old_server" ]]; then
        docker rm -f -v "$old_server" 2>/dev/null || true
    fi

    if ! docker run -di --name "$environ-galaxy-pc-nuxt3-$version" -p "${host_port}:3000" "$repo_addr/$environ-galaxy-pc-nuxt3:$version"; then
        echo "容器启动失败，请检查镜像和运行参数"
        exit 1
    fi

    sleep 3
    logs=$(docker logs "$environ-galaxy-pc-nuxt3-$version" 2>&1 | grep "Listening on http" || true)

    if [[ -z "$logs" ]]; then
        logs="未捕获到相关日志，请手动检查容器运行状态。"
    fi

    sendDingMessage "### **事件通知: $presenter 提交 $environ 构建**\n\n#### 状态: 已完成\n- 镜像: $environ-galaxy-pc-nuxt3:$version\n- 日志简报:\n$logs\n---\n"

    if ! docker push "$repo_addr/$environ-galaxy-pc-nuxt3:$version"; then
        sendDingMessage "### **告警通知: 镜像推送失败**\n#### 状态：待处理\n- 提交人: $presenter\n- 原因: 镜像推送失败，请检查网络或权限"
        exit 1
    fi
}

# 输入校验函数
validate_input() {
    # 检查是否为构建操作
    if [[ "$build" != "build" ]]; then
        echo "非构建操作,跳过"
        exit 0
    fi

    # 校验提交格式
    if ! [[ $commit_message =~ ^\[build-(rc|public)\]\s*v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        sendDingMessage "### **告警通知: 提交格式不符合要求**\n#### 状态：待处理\n- 提交人: $presenter\n- 提交记录为: $commit_message\n- 正确格式为: [build-public|rc]version"
        exit 1
    fi

    # 校验环境类型
    case $environ in
        rc|public)
            app_dir="$work_dir/galaxy-pc-nuxt3"
            build_image "$app_dir"
            deploy_app
            ;;
        *)
            sendDingMessage "### **告警通知: 无法匹配环境类型**\n#### 状态：待处理\n- 提交人: $presenter\n- 原因: 无法匹配环境类型$environ"
            exit 1
            ;;
    esac
}

main() {
    fetch_and_build

    write_env_vars

    validate_input

}

main
