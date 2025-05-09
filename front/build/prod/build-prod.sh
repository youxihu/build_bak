#!/bin/bash

# 工作目录
work_dir="/home/jenkins/build"
build_dir="$work_dir/galaxy-pc-nuxt3/build/prod"
execute_dir="/home/jenkins/execute"
target_dir="/prod-working-dir/pc_prod"

# 加载告警发送脚本 加载本地变量 加载传递变量
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

# 构建镜像并推送至镜像仓库
build_image() {
    local app_dir=$1

    cd "$app_dir" || { echo "无法切换到应用目录: $app_dir"; exit 1; }

    if ! docker build -t "$repo_addr/$environ-galaxy-pc-nuxt3:$version" .; then
        echo "镜像构建失败，请检查 Dockerfile 和构建环境"
        exit 1
    fi

    if ! echo "$repo_passwd" | docker login -u "$repo_user" --password-stdin "$repo_addr"; then
        echo "登录镜像仓库失败，请检查用户名和密码"
        exit 1
    fi

    if ! docker push "$repo_addr/$environ-galaxy-pc-nuxt3:$version"; then
         sendDingMessage "### **告警通知: 镜像推送失败**\n#### 状态：待处理\n- 提交人: $presenter\n- 原因: 镜像推送失败，请检查网络或权限"
         exit 1
    fi
}

deploy_app() {
    scp  $build_dir/load-env.sh bbx-master:$target_dir
    scp  $build_dir/deploy-prod.sh bbx-master:$target_dir
    ssh  bbx-master "bash $target_dir/deploy-prod.sh"
}

validate_input() {
  # 检查是否为构建操作
     if [[ "$build" != "buildonline" ]]; then
         echo "非构建操作,跳过"
         exit 0
     fi

     # 校验提交格式
     if ! [[ $commit_message =~ ^\[buildonline-online\]\s*v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
         sendDingMessage "### **告警通知: 提交格式不符合要求**\n#### 状态：待处理\n- 提交人: $presenter\n- 提交记录为: $commit_message\n- 正式环境构建格式为: [buildonline-online]version"
         exit 1
     fi

     case $environ in
         online)
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