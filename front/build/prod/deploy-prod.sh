#!/bin/bash

# 工作目录和加载变量
source_dir="/prod-working-dir/pc_prod"
source $source_dir/node-local-info.sh
source $source_dir/load-env.sh
source $source_dir/notice.sh

if ! echo "$repo_passwd" | docker login -u "$repo_user" --password-stdin "$repo_addr"; then
    echo "登录镜像仓库失败，请检查用户名和密码"
    exit 1
fi

if ! docker pull "$repo_addr/$environ-galaxy-pc-nuxt3:$version"; then
    echo "拉取镜像失败，请检查镜像地址和版本"
    exit 1
fi

old_server=$(docker ps -a | grep "$environ-galaxy-pc-nuxt3" | awk '{print $1}')
if [[ -n "$old_server" ]]; then
    docker rm -f -v "$old_server" 2>/dev/null || true
fi

# 部署新容器
deploy_container() {
    local host_port="${HOST_PORT:-23730}"

    if ! docker run -di --name "$environ-galaxy-pc-nuxt3-$version" -p "${host_port}:3000" "$repo_addr/$environ-galaxy-pc-nuxt3:$version"; then
        echo "容器启动失败，请检查镜像和运行参数"
        exit 1
    fi

    sleep 3
    logs=$(docker logs "$environ-galaxy-pc-nuxt3-$version" 2>&1 | grep "Listening on http" || true)

    if [[ -z "$logs" ]]; then
        logs="未捕获到相关日志，请手动检查容器运行状态。"
    fi

    sendDingMessage "### **事件通知: $presenter 提交 $environ 构建**\n\n#### 状态: 已完成\n- 镜像: $environ-galaxy-pc-nuxt3:$version\n- 日志简报:\n$logs"
}

deploy_container