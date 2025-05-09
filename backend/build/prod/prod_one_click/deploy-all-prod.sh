#!/bin/bash
# 设置镜像仓库地址
#repo="192.168.2.254:54800"
repo="repo.biaobiaoxing.com:54800"
mount_dir="/workserver/work-docker/work-configs"
source /prod-working-dir/deploy-notice.sh
source /prod-working-dir/prod_one_click/update-item.sh

cd /prod-working-dir/prod_one_click || exit 1

# 创建临时文件和清理函数
temp_image_list=$(mktemp)
old_containers_file=$(mktemp)
container_names_file=$(mktemp)

trap 'rm -f "$temp_image_list" "$old_containers_file" "$container_names_file"' EXIT

# 获取需要更新的镜像信息
get_images() {
    awk -v item="$item" '
      /### version/ { if (found) exit; found=0 }
      /'"$item"'/ { found=1 }
      found
    ' CHANGELOG.md | grep -vE '^$|NOCHANGE' | grep -A 9999 "服务" |
    awk -F '|' 'NR > 2 { print $2, $3, $4 }' |
    sed 's/^[[:space:]]*//;s/[[:space:]]*$//' |
    awk -v repo="$repo" '{ print repo "/rc-" $1 "-" $2":v" $3 }'
}

# 拉取镜像并保存至临时文件
get_images > "$temp_image_list"
images=$(<"$temp_image_list")

# 拉取镜像
for image in $images; do
     docker pull "$image" || echo "Failed to pull image $image"
done

# 停止并移除旧容器
stop_old_containers() {
        local stop_name="$1"

        old_server=$(docker ps -a | grep "$stop_name" | awk '{print $1}')
        docker rm -f -v "$old_server" 2>/dev/null
}

# 启动新容器
start_container() {
    local instance_name="$1"
    local image_name="$2"
    local volume_name="$3"
    local ports="$4"

    case "$instance_name" in
        *"im"*)
            docker run -di --restart always --name "$instance_name" \
                --network host \
                -e BBX_SAAS_RUNTIME_ENV=online \
                -v "$mount_dir/$volume_name:/app-acc/configs" \
                -v "$mount_dir/$volume_name/logs:/app-acc/logs" \
                "$repo/$image_name" || echo "Failed to start container $instance_name"
            ;;
        *)
            docker run -di --restart always --name "$instance_name" \
                -e BBX_SAAS_RUNTIME_ENV=online \
                -v "$mount_dir/$volume_name:/app-acc/configs" \
                -v "$mount_dir/$volume_name/logs:/app-acc/logs" \
                $ports "$repo/$image_name" || echo "Failed to start container $instance_name"
            ;;
    esac
}


# 根据 Item 确定端口映射的函数
get_ports(){
      local item="$1"
      local container_name="$2"

      case "$item" in
          "bbx")
              case "$container_name" in
                  *"admin"*) echo "-p 23799:9900";;
                  *"web"*) echo "-p 23789:8900";;
                  *"interface"*) echo "-p 23788:8800";;
                  *) echo "";
              esac
              ;;
          "bbz")
              case "$container_name" in
                  *"admin"*) echo "-p 27777:7700";;
                  *"web"*) echo "-p 27767:6700";;
                  *"interface"*) echo "-p 27766:6600";;
                  *) echo "";
              esac
              ;;
      esac
}

while read -r line; do
    image_name=$(echo "$line" | cut -d '/' -f 2)
    container_name=$(echo "$image_name" | sed 's/rc-/online-/;s/:/-/')
    volume_name=$(echo "$container_name" | awk -F '-v' '{print $1}')

    # 获取端口映射
    ports=$(get_ports "$item" "$container_name")
    # 停止旧容器
    stop_old_containers "$volume_name"
    # 启动新容器
    start_container "$container_name" "$image_name" "$volume_name" "$ports"
done < "$temp_image_list"

sendDingMessage "$NN_Webhook_Token" "$ONE_CLICK_title" "### **通知: 正式环境已部署**\n\n#### 状态: 已完成\n- 部署模式: 全量部署\n- 部署层次: $item后端\n---\n$NIU
