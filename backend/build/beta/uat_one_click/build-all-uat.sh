#!/bin/bash

# 设置工作目录
source_dir="/home/jenkins/build/bbx-saas/build/beta/uat_one_click"
target_dir="/home/jenkins/execute/beta/uat_one_click"
cd "$source_dir" || { echo "无法进入目录 $source_dir"; exit 1; }

if git pull origin master; then
    echo "代码拉取成功"
else
    echo "git pull 失败，请检查"
    exit 1
fi

# 获取当前日期
now=$(date +%Y-%m-%d)
echo "UAT全量更新日期: $now"

# 读取项目名称
read -p "请输入项目名称 (bbx 或 bbz): " realitem

# 根据输入的项目名称决定忽略项
case "$realitem" in
    bbx)
        ignoreitem="bbz"
        echo "$realitem" > update-item.sh
        ;;
    bbz)
        ignoreitem="bbx"
        echo "$realitem" > update-item.sh
        ;;
    *)
        echo "项目错误, 识别不到 $realitem"
        exit 1
        ;;
esac
# 获取当前在 Docker 中运行的bbx|bbz项目、public|rc服务及其版本
docker_versions=$(docker -H tcp://192.168.2.254:2375 ps --format '{{.Names}}' | grep public | grep -v "$ignoreitem" | sed 's/public/rc/' | awk -F '[-]' '{printf "192.168.2.254:54800/%s-%s-%s:%s\n", $1, $2, $3, $4}')

# 检查 docker_versions 是否为空
if [[ -z "$docker_versions" ]]; then
    echo "没有找到符合条件的 Docker 容器。"
else
    # 输出符合条件的Image到文件
    echo "$docker_versions" > update-app.sh
fi

cat update-app.sh
read -p "更新的项目是否正确 (y 或 n): " confirm
if [ "$confirm" == "y" ]; then
    git add *
    git commit -m "[uat_one_click_update]$realitem-$now"
    git push origin master
    echo "推送成功"
else
    echo "未确认，将退出"
    exit 0
fi

scp $source_dir/update-app.sh \
    $source_dir/update-item.sh \
    $source_dir/deploy-all-uat.sh \
    bbx254:$target_dir && \
ssh bbx254 "bash $target_dir/deploy-all-uat.sh"

