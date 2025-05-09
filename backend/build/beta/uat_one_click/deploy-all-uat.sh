#!/bin/bash
# 指定Deploy执行路径
target_dir="/home/jenkins/execute/beta/uat_one_click"
File="$target_dir/update-app.sh"
FlushItem=$(cat $target_dir/update-item.sh)
volumedir="/home/servervolume"

# 删除旧容器的函数
remove_old_container(){
   local flush_item="$1"
   local old_app="$2"

   old_container=$(docker ps -a | grep rc | grep "$old_app" | awk '{print $1}')
   docker rm -f -v "$old_container" 2>/dev/null

}

# 启动新容器的函数
start_container() {
    local container_name="$1"
    local target_image="$2"
    local volume_name="$3"
    local ports="$4"

    docker run -di --restart always --name "$container_name" -e BBX_SAAS_RUNTIME_ENV=rc \
        -v "$volumedir/$volume_name:/app-acc/configs" \
        -v "$volumedir/$volume_name/logs:/app-acc/logs" \
        $ports "$target_image" || echo "Failed to start container $container_name"
}

# 根据 FlushItem 确定端口映射的函数
get_ports() {
    local flush_item="$1"
    local container_name="$2"

    case "$flush_item" in
        "bbx")
            case "$container_name" in
                *"admin"*) echo "-p 54199:9900";;
                *"web"*) echo "-p 54189:8900";;
                *"interface"*) echo "-p 54188:8800";;
                *"im"*) echo "-p 54579:9009" "-p 11004:10004";;
                *) echo "";
            esac
            ;;
        "bbz")
            case "$container_name" in
                *"admin"*) echo "-p 57177:7700";;
                *"web"*) echo "-p 57167:6700";;
                *"interface"*) echo "-p 57166:6600";;
                *"im"*) echo "-p 54579:9009" "-p 11004:10004";;
                *) echo "";
            esac
            ;;
    esac
}

# 主流程
while IFS= read -r line; do
    TARGET_IMAGE="$line"
    # 将 'rc-' 替换为 'public-' 以生成目标镜像
    SOURCE_IMAGE="${TARGET_IMAGE/rc-/public-}"

    # 标签并推送镜像
    if docker tag "$SOURCE_IMAGE" "$TARGET_IMAGE"; then
        docker push "$TARGET_IMAGE" || echo "Failed to push $TARGET_IMAGE"
    else
        echo "Failed to tag $SOURCE_IMAGE as $TARGET_IMAGE"
        continue
    fi

    # 提取容器名称和挂载目录名称
    uat_container_name=$(echo "$TARGET_IMAGE" | cut -d '/' -f 2 | sed 's/:/-/')
    uat_container_volume=$(echo "$TARGET_IMAGE" | cut -d '/' -f 2 | awk -F ':' '{print $1}')
    # 提取旧容器名称
    uat_old_container_name=$(echo "$TARGET_IMAGE"| cut -d "/" -f 2 | cut -d ":" -f 1)
    # 获取端口映射
    ports=$(get_ports "$FlushItem" "$uat_container_name")
    # 移除旧容器
    remove_old_container "$FlushItem" "$uat_old_container_name"
    # 启动容器
    start_container "$uat_container_name" "$TARGET_IMAGE" "$uat_container_volume" "$ports"
done < "$File"



