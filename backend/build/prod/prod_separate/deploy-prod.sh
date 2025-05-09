#!/bin/bash
##from YouXiHu(y994189@163.com)
#脚本为正式环境后端服务更新的发布脚本(2)
#脚本主要负责发布已确认需更新的项目、应用、版本；目前项目有且仅有为BBX|BBZ
#脚本逻辑:
#1.接收到部署机传参后生效变量,生效本地变量
#2.通过变量得知发版的项目应用及版本号,登录Nexus远程仓库(repo.biaobiaoxing.com)拉取对应镜像 
#3.根据项目和应用名称处以不同的运行逻辑,如端口的映射,本地目录与容器真实目录的挂载
#4.挂载本地目录到容器内部时会判断是否已有该目录,若没有会通过脚本创建,并连接远程配置文件(Nacos)及配置鉴权信息
#5.最后根据对应信息实现对应项目应用版本的正式发布,发布完成后发送钉钉消息至钉钉群以通知发布结果
#=============正文如下===========================正文如下=================正文如下==========================正文如下===============#
# 生效本地变量
# 生效传参变量
# 生效钉钉通知
source /prod-working-dir/prod_separate/local-prod-info.sh
source /prod-working-dir/prod_separate/load-env.sh
source /prod-working-dir/deploy-notice.sh
itemapp="${item}${app}"

# 登录代码仓库拉最新镜像
echo "$repo_passwd" | docker login -u "$repo_user" --password-stdin "$repo_addr"
docker pull "$repo_addr/$environ-$item-$app:$version"
old_server=$(docker ps -a | grep "$environ-$item-$app" | awk '{print $1}')
docker rm -f -v "$old_server" 2>/dev/null

sendMessages() {
    case $presenter in
        yrzs)
            trigger_word="$JIGE"
            webhook_token="$JG_Webhook_Token"
            title="$JG_title"
            ;;

        SevenDreamYang)
            trigger_word="$HQ"
            webhook_token="$HQ_Webhook_Token"
            title="$HQ_title"
            ;;

        mars|Mars)
            trigger_word="$QQ"
            webhook_token="$QQ_Webhook_Token"
            title="$QQ_title"
            ;;

        *)
            trigger_word="$NIU"
            webhook_token="$NN_Webhook_Token"
            title="$CICD_title"
            ;;
    esac

    # 组合消息
    message="### **事件通知: $presenter 提交 $environ 构建**\n\n#### 状态: 已完成\n- 镜像: $environ-$item-$app-$version\n- 日志简报: 请前往日志平台查看\n- 日志平台: [http://kibana](http://112.124.12.90:9061/login?next=%2F)\n---\n$trigger_word"

    # 发送消息
    sendDingMessage "$webhook_token" "$title" "$message"
}

docker_common() {
    local port=$1
    local portOption=""
    if [ -n "$port" ]; then
        portOption="-p $port:${!itemapp}"
    fi

    # 根据应用类型处理不同运行逻辑
    case $app in
        im)
            docker run -di --name "$environ-$item-$app-$version" \
                --network host \
                -v "$volumedir/$environ-$item-$app/logs:/app-acc/logs" \
                -v "$volumedir/$environ-$item-$app:/app-acc/configs" \
                -e BBX_SAAS_RUNTIME_ENV="$environ" \
                --restart always \
                "$repo_addr/$environ-$item-$app:$version"
            ;;
        *)
            docker run -di --name "$environ-$item-$app-$version" \
                $portOption \
                -v "$volumedir/$environ-$item-$app/logs:/app-acc/logs" \
                -v "$volumedir/$environ-$item-$app:/app-acc/configs" \
                -e BBX_SAAS_RUNTIME_ENV="$environ" \
                --restart always \
                "$repo_addr/$environ-$item-$app:$version"
            ;;
    esac
   # 运行后发送钉钉通知
   sendMessages
}



docker_run() {
    local port=$1
    docker_common $port
}

docker_no_port() {
    docker_common
}

# 检查文件是否存在，如果不存在则创建并写入内容
if [ ! -f "$volumedir/$environ-$item-$app/remote.yaml" ]; then
    mkdir -p "$volumedir/$environ-$item-$app"

    # 根据 item 的值设置 data_id
    if [ "$item" = "main" ]; then
        data_id="${app}.yaml"
    else
        data_id="${item}-${app}.yaml"
    fi

    eval "cat <<EOF >\"$volumedir/\$environ-\$item-\$app/remote.yaml\"
config:
    type: 'nacos'
    nacos:
        address: '172.16.143.229'
        port: '8848'
        namespace_id: \"\${${environ}id}\"
        group: 'DEFAULT_GROUP'
        data_id: \"${data_id}\"
        username: \"\${${environ}user}\"
        password: \"\${${environ}pwd}\"
EOF
"
fi

case $environ in
    online)
        case $app in
            admin|interface|web)
                case $item in
                    bbx)
                        docker_run "237${!itemapp:0:2}"
                        ;;
                    bbz)
                        docker_run "277${!itemapp:0:2}"
                        ;;
                esac
                ;;
            im)
                docker_run "2${!itemapp:0:4}" "29004:10004"
                ;;
            *)
                docker_no_port
                ;;
        esac
        ;;
esac

