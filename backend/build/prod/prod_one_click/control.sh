#!/bin/bash
##from YouXiHu(y994189@163.com)
#脚本为正式环境全量更新前置脚本(1)
#脚本主要负责确认需更新的项目、应用、版本；目前项目有且仅有为BBX|BBZ
#脚本逻辑:
#1.进入到部署者私有目录的项目中，要求部署人员手动输入本次发版的项目及版本号.
#2.根据Docker的2375远程调用端口查询在预发环境已经确认了的项目、应用、版本号，并记录.
#3.将记录下来的信息通过正则匹配拆分为项目、应用、版本号的独立个体，并按markdown的格式写入CHANGELOG.
#4.在正确提交发版详细信息后,将修改信息发布到远程代码仓库(Gitlab),佐以Tag标识来触发Jenkins的构建，即production-env-local.sh和production-env-onlinegolive.sh脚本.
#=============正文如下===========================正文如下=================正文如下==========================正文如下===============#
#定义工作目录即项目所在地并进入
workdir="/home/jenkins/build/bbx-saas"
cd "$workdir" || { echo "无法进入目录 $workdir"; exit 1; }

if git pull origin master; then
    echo "代码拉取成功"
else
    echo "git pull 失败，请检查"
    exit 1
fi

# 定义发版依据文件
CHANGELOG="CHANGELOG.md"

# 获取当前日期
now=$(date +%Y-%m-%d)
echo "本次发版日期: $now"

# 读取项目名称
read -p "请输入项目名称 (bbx 或 bbz): " realitem

# 拿到本次发版的项目名称,作检索时忽略另一项目以完成项目、应用、版本的提取
case "$realitem" in
    bbx)
        ignoreitem="bbz"
        ;;
    bbz)
        ignoreitem="bbx"
        ;;
    *)
        echo "项目错误, 识别不到 realitem"
        exit 1
        ;;
esac

# 读取用户输入的新版本号
read -p "请输入本次发版的确认版本号（格式：x.y.z）: " new_version_number

# 获取当前在 Docker 中运行的项目、服务及其版本
docker_versions=$(docker -H tcp://192.168.2.254:2375 ps --format '{{.Names}}' | grep rc | grep -v "$ignoreitem" | awk -F '[-]' '{gsub(/^v/, "", $4); print $2 "-" $3 "-" $4}')
#docker_versions=$(docker -H tcp://192.168.0.214:2375 ps -a --format '{{.Names}}' | grep rc | grep -v "$ignoreitem" | awk -F '[-]' '{gsub(/^v/, "", $4); print $2 "-" $3 "-" $4}')

# 使用临时文件来存储 awk 的输出 用于提取关于项目的最近一次发版的版本比对
awk_output=$(mktemp)
awk -v item="$realitem" '
/### version/ {
    if (found_item) {
        print start_line, NR - 1
        exit
    }
    if ($0 ~ item) {
        in_bbx_segment = 1
    } else {
        in_bbx_segment = 0
    }
    if (found_item) {
        end_line = NR - 1
        print start_line, end_line
        exit
    }
    line_count = 0
    start_line = NR
}
{
    if (in_bbx_segment) next
    if ($0 ~ item) found_item = 1
}
END {
    if (found_item) {
        print start_line, NR - 1
    }
}
' "$CHANGELOG" > "$awk_output"

# 读取行号范围
read start_line end_line < "$awk_output"

# *调试：输出行号范围以确认
#echo "Start line: $start_line"
#echo "End line: $end_line"

# 提取最新版本的服务和版本信息到临时文件
temp_file=$(mktemp)
sed -n "${start_line},${end_line}p" "$CHANGELOG" | tail -n +5 > "$temp_file"

# 从临时文件读取数据到关联数组
declare -A latest_versions
while IFS='|' read -r _ appitem service version remark _; do
    if [[ -n $appitem && -n $service && -n $version ]]; then
        appitem=$(echo "$appitem" | xargs)
        service=$(echo "$service" | xargs)
        version=$(echo "$version" | xargs)
        latest_versions["$appitem:$service"]=$version
    fi
done < "$temp_file"

# 删除临时文件
rm -f "$temp_file" "$awk_output"

# 创建新的版本记录
new_version="### version $new_version_number\n\n1. $realitem 项目线上服务版本更新(NOCHANGE将不更新)\n\n| 项目       | 服务       | 版本       | 备注   |\n|:-----------|:-----------|:-----------|:-------|"

# 遍历每个服务并生成表格行
for line in $docker_versions; do
    appitem=$(echo "$line" | awk -F '-' '{print $1}')
    service=$(echo "$line" | awk -F '-' '{print $2}')
    version=$(echo "$line" | awk -F '-' '{print $3}')
    remark=""
    key="$appitem:$service"
    if [[ ${latest_versions[$key]} == "$version" ]]; then
        remark="NOCHANGE"
    fi
    new_version="${new_version}\n$(printf '| %-9s | %-10s | %-9s | %-6s |' "$appitem" "$service" "$version" "$remark")"
done

# 在新的版本记录前面加一个空行，以确保它与上一个版本记录之间有间隔
new_version="\n${new_version}\n"

# 将新的版本记录插入到 CHANGELOG.md 文件的第三行
sed -i "3i\\
${new_version}\\
" "$CHANGELOG"

echo "CHANGELOG.md 更新成功"
echo "本次发版项目:$realitem"
echo "本次项目发布版本:$new_version_number"

# 获取本次发版内容
upd=$(awk '/### version [0-9]+\.[0-9]+\.[0-9]+/{c++; if(c==2) exit} c==1' "$CHANGELOG" | grep -v '^$' | grep -v "NOCHANGE" | grep -A 9999 "服务" | awk -F '|' 'NR>2 {print $2, $3,$4}')
# 判断如果要更新的内容为空则退出脚本
if [ -z "$upd" ]; then
    echo "$realitem没有要更新的内容"
    exit 0
else
   echo -e "本次要更新的容器有:\n$upd"
fi

# 提示用户确认并提交更改
read -p "即将上传本次发版的 CHANGELOG 到 master, 请确认本次更新内容是否正确, yes or no: " adda
if [ "$adda" == "yes" ]; then
    git add "$CHANGELOG"
    git commit -m "[onlinegolive]$realitem-$now"
    git push origin master
    echo "推送成功"
else
    echo "未确认，将退出"
    exit 0
fi

# 提示用户确认创建标签
read -p "即将对本次发版 $new_version_number 打标记, 请确认是否创建带标签的版本, yes or no: " tagg
if [ "$tagg" == "yes" ]; then
    git tag -a "$new_version_number" -m "[onlinegolive]$realitem-$now"
    git push origin "$new_version_number"
    echo "标签 $new_version_number 创建成功"
    echo -e "标记 push 成功, 已触发 Jenkins 的 online cicd 脚本, 请去 Jenkins 查看:\nhttp://192.168.2.254:8998/jenkins/job/bbx-tag"
else
    echo "未确认，将退出"
    exit 0
fi

