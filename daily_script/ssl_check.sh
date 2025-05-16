#!/bin/bash
# 定义变量
Ssl_home="/etc/letsencrypt/live"
Nginx_Ssl_home="/workserver/work-local/nginx/nginx-conf.d/ssl"
domains=(
    	"www.mps.gov.cn"
    	"www.mod.gov.cn"
    	"www.ccdi.gov.cn"
)

# 生效钉钉通知(网络皇帝机器人)
source /workserver/work-local/sys_bash_alarm/SslTz.sh
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
cd /opt/ssl_check.dir

# 检查证书是否将在30天内过期
check_expiry() {
    local domain="$1"
    local ssl_file="ssl_${domain}.txt"
    local expire_date=$(awk '/expire date:/ {print $4, $5, $6, $7}' "$ssl_file")

    # 提取月份、日期和年份
    local month=$(echo "$expire_date" | awk '{print $1}')
    local day=$(echo "$expire_date" | awk '{print $2}')
    local year=$(echo "$expire_date" | awk '{print $4}')

    case $month in
    "1月" | "Jan") month="01" ;;
    "2月" | "Feb") month="02" ;;
    "3月" | "Mar") month="03" ;;
    "4月" | "Apr") month="04" ;;
    "5月" | "May") month="05" ;;
    "6月" | "Jun") month="06" ;;
    "7月" | "Jul") month="07" ;;
    "8月" | "Aug") month="08" ;;
    "9月" | "Sep") month="09" ;;
    "10月" | "Oct") month="10" ;;
    "11月" | "Nov") month="11" ;;
    "12月" | "Dec") month="12" ;;
    esac

    # 格式化过期日期
    local formatted_expire_date="$year-$month-$day"
    local current_date=$(date +%F)

    # 将日期字符串转换为时间戳（秒）
    local timestamp1=$(date -d "$formatted_expire_date" +%s)
    local timestamp2=$(date -d "$current_date" +%s)

    # 计算日期差值（秒）和 差值对应的天数
    local difference=$((timestamp1 - timestamp2))
    local days_difference=$((difference / 86400))  # 86400 秒是一天的秒数

    if [ $days_difference -lt 16 ]; then
        # 只记录必要的日志并静默执行 certbot，避免输出过多信息
        certbot certonly --nginx -d "$domain" --force-renew --quiet

        # 更新证书
        cp -f "$Ssl_home/$domain/fullchain.pem" "$Nginx_Ssl_home/$domain/pem.pem"
        cp -f "$Ssl_home/$domain/privkey.pem" "$Nginx_Ssl_home/$domain/key.key"
        nginx -s reload

        # 触发警告信息
        warning_message="### **事件通知: SSL证书更换**\n#### 事件状态 : 成功\n#### 证书详情 : \n- 域名 : [$domain](https://$domain)\n- 原过期时间 : $formatted_expire_date\n- 备注 : 本次更新由自动化运维系统触发\n- 提醒 : 请访问对应域名以确认更新情况\n---\n$Long"
        sendLong $warning_message

        current_time=$(date "+%Y-%m-%d %H:%M:%S")
        echo "$current_time: $domain 的 SSL 证书已更新" >> check_certificate.log
    else
        # 记录日志，说明当前证书无需更新
        current_time=$(date "+%Y-%m-%d %H:%M:%S")
        echo "$current_time: $domain 的 SSL 证书有效至$formatted_expire_date,还有$days_difference天,暂无更新需求" >> check_certificate.log
    fi
}


# 循环检查每个域名的证书
for domain in "${domains[@]}"; do
    # 先静默地抓取证书信息
    curl "https://$domain" -k -v -s -o /dev/null 2> "/opt/ssl_check.dir/ssl_${domain}.txt"

    # 调用 check_expiry 函数并检查是否有警告信息
    check_expiry "$domain"
done