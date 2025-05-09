#!/bin/bash
##from YouXiHu(y994189@163.com)
#脚本为正式环境全量更新Jenkins端触发脚本(2)
#脚本负责将全量更新前置脚本(1)写入的CHANGELOG日志传输到远程正式服务器并告知远程正式服务器要发布的项目准确信息
#脚本逻辑:
#1.进入到发布机的工作目录，忽略本地提交并拉取代码仓库的最新更新信息
#2.切换到对应的更新Tag
#3.将更新的项目名词取值并赋值再传值，发送给远程正式服务器
#4.远程执行deploy-all-prod.sh完成全量
#=============正文如下===========================正文如下=================正文如下==========================正文如下===============#
# 设置工作目录
work_dir="/home/jenkins/build/bbx-saas"
cd "$work_dir"  && echo "切换工作目录成功" || { echo "切换工作目录失败"; exit 1; }
#忽略本地代码 直接拉取仓库最新代码
git stash

git fetch --tags

git checkout  $(git describe --tags `git rev-list --tags --max-count=1`)

FlushItem=$(git log -1 --no-merges --pretty=%B | awk -F '[][ -]+' '{print $3}')
echo "item=$FlushItem" > $work_dir/build/prod/prod_one_click/update-item.sh

scp $work_dir/build/prod/prod_one_click/deploy-all-prod.sh \
    $work_dir/CHANGELOG.md \
    $work_dir/build/prod/prod_one_click/update-item.sh \
    bbx-master:/prod-working-dir/prod_one_click && \
ssh bbx-master "bash /prod-working-dir/prod_one_click/deploy-all-prod.sh"

