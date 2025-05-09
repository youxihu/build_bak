#!/bin/bash
##from YouXiHu(y994189@163.com)
#脚本为正式环境后端服务更新的前置脚本(1)
#脚本主要负责确认需更新的项目、应用、版本；目前项目有且仅有为BBX|BBZ
#脚本逻辑:
#1.通过Jenkins与Gitlab之间绑定,由特定的Log格式触发
#2.触发格式为[build-$env]$item-$app--$version 
#ps: $env-->环境(online) 
#    $item-->项目名称(bbx|bbz) 
#    $app-->服务名称(admin|interface|account|...)
#    $version-->版本号(v1.x.x|...)
#3.接受到Gitlab有代码更新后,脚本会触发部署机自动拉取最新代码,并提取git log 查看是否与触发条件一致,不一致则退出构建.
#4.一致且符合规范后,首先会读取git log将参数拆分并写入load-env.sh,以生效变量为之后操作提供基础
#5.使用读取的参数进到对应的项目应用目录进行代码编译、容器构建,并将镜像上传至Nexus远程的镜像仓库(repo.biaobiaoxing.com)
#6.构建全部完成后触发远程正式机的发布脚本
#=============正文如下===========================正文如下=================正文如下==========================正文如下===============#
# 设置工作目录/构建目录/执行目录/部署目录
work_dir="/home/jenkins/build"
build_dir="$work_dir/bbx-saas/build/prod/prod_separate"
execute_dir="/home/jenkins/execute"
target_dir="/prod-working-dir/prod_separate"
[ -d "$work_dir" ] || mkdir -p "$work_dir"
# 设置protoc路径到PATH中
export PATH=$PATH:/usr/local/bin
##生效牛牛
source "/home/sys_bash_send/send_alarm.sh"
# 获取最新 commit message及定义变量
source "$execute_dir/local-info.sh"
# 切换到工作目录
cd "$work_dir/bbx-saas"  && echo "切换工作目录成功" || { echo "切换工作目录失败"; exit 1; }

# 函数：拉取最新代码
fetch_and_build() {
    # 忽略本地修改，直接拉取最新代码
    git stash

    # 拉取最新代码
    if ! git pull origin master; then
        echo "git pull 失败，请检查"
        sendDingDing "### **告警通知: 推送构建失败**\n#### 状态：待处理\n#### $NIU:\n- 提交人: $presenter\n- 原因: 代码拉取失败\n- 请检查构建环境: $work_dir/bbx-saas\n- 本次构建已退出"
        exit 1
    else
        echo "代码拉取成功"
    fi

    # 执行构建
    make api && make common && make error && make enum
}

# 调用函数拉取最新代码
fetch_and_build

# 传输变量固定值到远程服务器的本地脚本
cat <<EOF >$build_dir/load-env.sh
export commit_message="$commit_message"
export build="$build"
export environ="$environ"
export item="$item"
export app="$app"
export version="$version"
export write_time="$(date +'%Y-%m-%d %H:%M:%S')"
export presenter="$presenter"
EOF


chmod +x $build_dir/load-env.sh
chmod +X $build_dir/deploy-prod.sh

set -e

build_app() {
    local app=$1
    local app_dir=$2

    # 判断应用目录是否不存在
    if [[ ! -d "$app_dir" ]]; then
        echo "应用目录不存在：$app_dir"
        sendDingDing "### **告警通知: 推送构建失败**\n#### 状态：待处理\n#### $NIU:\n- 提交人: $presenter\n- 原因: 应用目录不存在\n- 请检查工作目录是否存在: $app_dir\n- 本次构建已退出"
        exit 1
    fi

    # 如果目录存在，则继续执行构建流程
    cd "$app_dir" && make build
    docker build -t "$repo_addr/$environ-$item-$app:$version" .
    echo "$repo_passwd" | docker login -u "$repo_user" --password-stdin "$repo_addr"
    docker push "$repo_addr/$environ-$item-$app:$version"
    scp $work_dir/bbx-saas/build/prod/prod_separate/load-env.sh bbx-master:$target_dir
    scp $work_dir/bbx-saas/build/prod/prod_separate/deploy-prod.sh bbx-master:$target_dir
    ssh bbx-master "bash $target_dir/deploy-prod.sh"
}

# 如果不是 build行为，直接退出
if [[ "$build" != "buildonline" ]]; then
    echo "非构建操作，跳过"
    exit 0
fi

# 如果提交格式不符合要求，直接退出
if ! [[ $commit_message =~ ^\[buildonline-online\]([a-zA-Z0-9-]+)-([a-zA-Z0-9-]+)--(v[0-9]+\.[0-9]+\.[0-9]+)$ ]]; then
    echo "提交格式有误 错误格式为: $commit_message"
    sendDingDing "### **通报: 提交格式不符合要求**\n#### $NIU:\n- $presenter错误提交\n- 提交记录为$commit_message\n- 正确格式为: [buildonline-online]item-app-version\n- 本次构建失败并退出"
    exit 1
fi

# 根据环境和应用类型处理
case $environ in
    online)
        case $app in
            account|content|finance|project|iam|marketing|communal|operation|mall)
                if ! [[ $commit_message =~ ^\[buildonline-online\]main-[a-zA-Z0-9-]+--v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                    echo "提交格式不符合要求: $commit_message"
                    sendDingDing "### **通报: 提交格式不符合要求**\n#### $NIU:\n- $presenter错误提交\n- 提交记录:$commit_message\n- 正确格式: [buildonline-online]item-app-version\n- 本次构建失败并退出"
                    exit 1
                fi
                app_dir="$work_dir/bbx-saas/app/main/$app"
                ;;
            im|infra)
                if ! [[ $commit_message =~ ^\[buildonline-online\]common-[a-zA-Z0-9-]+--v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                    echo "提交格式不符合要求: $commit_message"
                    sendDingDing "### **通报: 提交格式不符合要求**\n#### $NIU:\n- $presenter错误提交\n- 提交记录为$commit_message\n- 正确格式: [buildonline-online]item-app-version\n- 本次构建失败并退出"
                    exit 1
                fi
                app_dir="$work_dir/bbx-saas/app/$app"
                ;;
            admin|interface|web)
                if ! [[ $commit_message =~ ^\[buildonline-online\](bbx|bbz)-[a-zA-Z0-9-]+--v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                    echo "提交格式不符合要求: $commit_message"
                    sendDingDing "### **通报: 提交格式不符合要求**\n#### $NIU:\n- $presenter错误提交\n- 提交记录为$commit_message\n- 正确格式: [buildonline-online]item-app-version\n- 本次构建失败并退出"
                    exit 1
                fi

                case $item in
                    bbx|bbz)
                        app_dir="$work_dir/bbx-saas/app/tenant/$item/$app"
                        ;;
                    *)
                        echo "无法匹配项目类型：$item"
                        sendDingDing "### **通报: 无法匹配项目类型**\n#### $NIU:\n- $presenter已触发build行为\n- 无法匹配项目类型$item\n- 本次构建已退出"
                        exit 1
                        ;;
                esac
                ;;
            *)
                echo "无法匹配应用类型：$app"
                sendDingDing "### **通报: 无法匹配应用类型**\n#### $NIU:\n- $presenter已触发build行为\n- 无法匹配服务类型$app\n- 本次构建已退出"
                exit 1
                ;;
        esac
        build_app $app $app_dir
        ;;
    *)
        echo "无法匹配环境类型：$environ"
        sendDingDing "### **通报: 无法匹配环境类型**\n#### $NIU:\n- $presenter已触发build行为\n- 无法匹配环境类型$environ\n- 本次构建已退出"
        exit 1
        ;;
esac


