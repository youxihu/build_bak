#!/bin/bash

# 引入系统初始化函数
./etc/rc.d/init.d/functions

# 设置环境语言为中文UTF-8
eport LANG=zh_CN.UTF-8

# 一级菜单
menu1() {
    clear
    cat <<EOF
----------------------------------------
|****   欢迎使用CentOS 7.9优化脚本    ****|
|****      博客地址: xxxxxx         ****|
----------------------------------------
1. 修改字符集
2. 关闭SELinux
3. 关闭Firewalld
4. 精简开机启动
5. 修改文件描述符
6. 安装常用工具及修改yum源
7. 优化系统内核
8. 加快SSH登录速度
9. 禁用Ctrl+Alt+Del重启
10. 设置时间同步
11. History优化
12. 系统日常巡检
13. 数据库备份
14. 封禁异常ip
15.一键部署LNMP环境
16.一键全部执行
17.返回上级菜单
18.退出

EOF
    read -p "请输入您的选择[1-18]:" num1
    case $num1 in
        1) localeset ;;
        2) selinuxset ;;
        3) firewalldset ;;
        4) simplifyboot ;;
        5) modifyfiledescriptor ;;
        6) installtools ;;
        7) optimizekernel ;;
        8) speedupssh ;;
        9) disablectrlaltdel ;;
        10) synctime ;;
        11) optimizehistory ;;
	12) xunjian ;;
	13) backupsql ;;
	14) banip;;
	15) LNMPinstall;;
        16) executeall ;;
        17) menu1 ;;
        18) exit ;;
        *) echo "请输入有效选项"; menu1 ;;
    esac
}

# 1. 修改字符集
localeset() {
    echo "========================修改字符集========================="
    # 将字符集修改为中文UTF-8
    cat > /etc/locale.conf <<EOF
LANG="zh_CN.UTF-8"
#LANG="en_US.UTF-8"
SYSFONT="latarcyrheb-sun16"
EOF
    # 应用修改
    source /etc/locale.conf
    echo "#cat /etc/locale.conf"
    cat /etc/locale.conf
    action "完成修改字符集" /bin/true
    echo "==========================================================="
    sleep 2
}

# 2. 关闭SELinux
selinuxset() {
    echo "========================禁用SELinux========================"
    # 检查SELinux是否已关闭
    selinux_status=$(grep "SELINUX=disabled" /etc/sysconfig/selinux | wc -l)
    if [ $selinux_status -eq 0 ]; then
        # 修改SELinux配置文件
        sed -i "s#SELINUX=enforcing#SELINUX=disabled#g" /etc/sysconfig/selinux
        setenforce 0
        echo '#grep SELINUX=disabled /etc/sysconfig/selinux'
        grep SELINUX=disabled /etc/sysconfig/selinux
        echo '#getenforce'
        getenforce
    else
        # 如果SELinux已经关闭，则提示已关闭
        echo 'SELINUX已处于关闭状态'
        echo '#grep SELINUX=disabled /etc/sysconfig/selinux'
        grep SELINUX=disabled /etc/sysconfig/selinux
        echo '#getenforce'
        getenforce
    fi
    # 显示操作完成信息
    action "完成禁用SELinux" /bin/true
    echo "==========================================================="
    sleep 2
}

# 3. 关闭Firewalld
firewalldset() {
    echo "=======================禁用Firewalld========================"
    # 停止Firewalld服务
    systemctl stop firewalld.service &> /dev/null
    echo
}

# 4. 精简开机启动
simplifyboot(){
    echo "=======================精简开机启动========================"
    systemctl disable auditd.service
    systemctl disable postfix.service
    systemctl disable dbus-org.freedesktop.NetworkManager.service
    echo '#systemctl list-unit-files | grep -E "auditd|postfix|dbus-org\.freedesktop\.NetworkManager"'
    systemctl list-unit-files | grep -E "auditd|postfix|dbus-org\.freedesktop\.NetworkManager"
    action "完成精简开机启动" /bin/true
    echo "==========================================================="
}

# 5. 修改文件描述符
modifyfiledescriptor(){
    limitset()
    {
        echo "======================修改文件描述符======================="
        echo '* - nofile 65535'>/etc/security/limits.conf
        ulimit -SHn 65535
        echo "#cat /etc/security/limits.conf"
        cat /etc/security/limits.conf
        echo "#ulimit -Sn ; ulimit -Hn"
        ulimit -Sn ; ulimit -Hn
        action "完成修改文件描述符" /bin/true
        echo "==========================================================="
    }
}

# 6. 安装常用工具及修改yum源
installtools(){
    echo "=================安装常用工具及修改yum源==================="
    yum install wget -y &> /dev/null
    if [ $? -eq 0 ];then
        cd /etc/yum.repos.d/
        \cp CentOS-Base.repo CentOS-Base.repo.$(date +%F)
            wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo &> /dev/null
            yum clean all &> /dev/null
            yum makecache &> /dev/null
    fi
    yum -y install ntpdate lsof net-tools telnet vim lrzsz tree nmap nc sysstat  &> /dev/null
    echo "====================安装常用工具及修改yum源完成=================================="
}


#7. 优化系统内核
optimizekernel(){
  echo "======================优化系统内核========================="
  chk_nf=$(cat /etc/sysctl.conf | grep conntrack | wc -l)
  if [ $chk_nf -eq 0 ]; then
    cat >>/etc/sysctl.conf<<EOF
net.ipv4.tcp_fin_timeout = 2
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_keepalive_time = 600
net.ipv4.ip_local_port_range = 4000 65000
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.tcp_max_tw_buckets = 36000
net.ipv4.route.gc_timeout = 100
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_synack_retries = 0
net.core.somaxconn = 16384
net.core.netdev_max_backlog = 16384
net.ipv4.tcp_max_orphans = 16384
net.netfilter.nf_conntrack_max = 25000000
net.netfilter.nf_conntrack_tcp_timeout_established = 180
net.netfilter.nf_conntrack_tcp_timeout_time_wait = 120
net.netfilter.nf_conntrack_tcp_timeout_close_wait = 60
net.netfilter.nf_conntrack_tcp_timeout_fin_wait = 120
EOF
    sysctl -p
  else
    echo "优化项已存在。"
  fi
  action "内核调优完成" /bin/true
  echo "==========================================================="
}

#8. 加快ssh登录速度
speedupssh(){
  echo "======================加快ssh登录速度======================"
  sed -i 's#^GSSAPIAuthentication yes$#GSSAPIAuthentication no#g' /etc/ssh/sshd_config
  sed -i 's/#UseDNS yes/UseDNS no/g' /etc/ssh/sshd_config
  systemctl restart sshd.service
  echo "#grep GSSAPIAuthentication /etc/ssh/sshd_config"
  grep GSSAPIAuthentication /etc/ssh/sshd_config
  echo "#grep UseDNS /etc/ssh/sshd_config"
  grep UseDNS /etc/ssh/sshd_config
  action "完成加快ssh登录速度" /bin/true
  echo "==========================================================="
}

#9. 禁用ctrl+alt+del重启
disablectrlaltdel(){
  echo "===================禁用ctrl+alt+del重启===================="
  rm -rf /usr/lib/systemd/system/ctrl-alt-del.target
  action "完成禁用ctrl+alt+del重启" /bin/true
  echo "==========================================================="
}

#10. 设置时间同步
synctime(){
  echo "=======================设置时间同步========================"
  yum -y install ntpdate &> /dev/null
  if [ $? -eq 0 ]; then
    /usr/sbin/ntpdate cn.pool.ntp.org
    echo "*/5 * * * * /usr/sbin/ntpdate ntp.aliyun.com &>/dev/null" >> /var/spool/cron/root
  else
    echo "ntpdate安装失败"
    exit $?
  fi
  action "完成设置时间同步" /bin/true
  echo "==========================================================="
}

#11. history优化
optimizehistory(){
  echo "========================history优化========================"
  chk_his=$(cat /etc/profile | grep HISTTIMEFORMAT | wc -l)
  if [ $chk_his -eq 0 ]; then
    cat >> /etc/profile <<'EOF'
#设置history格式
export HISTTIMEFORMAT="[%Y-%m-%d %H:%M:%S] [`whoami`] [`who am i|awk '{print $NF}'|sed -r 's#[()]##g'`]: "
#记录shell执行的每一条命令
export PROMPT_COMMAND='\
if [ -z "$OLD_PWD" ];then
    export OLD_PWD=$PWD;
fi;
if [ ! -z "$LAST_CMD" ] && [ "$(history 1)" != "$LAST_CMD" ]; then
    logger -t `whoami`_shell_dir "[$OLD_PWD]$(history 1)";
fi;
export LAST_CMD="$(history 1)";
export OLD_PWD=$PWD;'
EOF
    source /etc/profile
  else
    echo "优化项已存在。"
  fi
  action "完成history优化" /bin/true
  echo "==========================================================="
}

#12.日常系统巡检脚本
xunjian(){
#Linux 系统日常巡检脚本，巡检内容包含了，磁盘，内存 cpu 进程文件更改，用户登录等一系列的操作 。
#报告以邮件发送到邮箱 在log下生成巡检报告。

IPADDR=$(ifconfig ens33|grep 'inet addr'|awk -F '[ :]' '{print $13}')
#环境变量PATH没设好，在cron里执行时有很多命令会找不到
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin
source /etc/profile

[ $(id -u) -gt 0 ] && echo "请用root用户执行此脚本！" && exit 1
centosVersion=$(awk '{print $(NF-1)}' /etc/redhat-release)
VERSION="2020-03-16"

#日志相关
PROGPATH=`echo $0 | sed -e 's,[\\/][^\\/][^\\/]*$,,'`
[ -f $PROGPATH ] && PROGPATH="."
LOGPATH="$PROGPATH/log"
[ -e $LOGPATH ] || mkdir $LOGPATH
RESULTFILE="$LOGPATH/HostDailyCheck-$IPADDR-`date +%Y%m%d`.txt"


#定义报表的全局变量
report_DateTime="" #日期 ok
report_Hostname="" #主机名 ok
report_OSRelease="" #发行版本 ok
report_Kernel="" #内核 ok
report_Language="" #语言/编码 ok
report_LastReboot="" #最近启动时间 ok
report_Uptime="" #运行时间（天） ok
report_CPUs="" #CPU数量 ok
report_CPUType="" #CPU类型 ok
report_Arch="" #CPU架构 ok
report_MemTotal="" #内存总容量(MB) ok
report_MemFree="" #内存剩余(MB) ok
report_MemUsedPercent="" #内存使用率% ok
report_DiskTotal="" #硬盘总容量(GB) ok
report_DiskFree="" #硬盘剩余(GB) ok
report_DiskUsedPercent="" #硬盘使用率% ok
report_InodeTotal="" #Inode总量 ok
report_InodeFree="" #Inode剩余 ok
report_InodeUsedPercent="" #Inode使用率 ok
report_IP="" #IP地址 ok
report_MAC="" #MAC地址 ok
report_Gateway="" #默认网关 ok
report_DNS="" #DNS ok
report_Listen="" #监听 ok
report_Selinux="" #Selinux ok
report_Firewall="" #防火墙 ok
report_USERs="" #用户 ok
report_USEREmptyPassword="" #空密码用户 ok
report_USERTheSameUID="" #相同ID的用户 ok 
report_PasswordExpiry="" #密码过期（天） ok
report_RootUser="" #root用户 ok
report_Sudoers="" #sudo授权 ok
report_SSHAuthorized="" #SSH信任主机 ok
report_SSHDProtocolVersion="" #SSH协议版本 ok
report_SSHDPermitRootLogin="" #允许root远程登录 ok
report_DefunctProsess="" #僵尸进程数量 ok
report_SelfInitiatedService="" #自启动服务数量 ok
report_SelfInitiatedProgram="" #自启动程序数量 ok
report_RuningService="" #运行中服务数 ok
report_Crontab="" #计划任务数 ok
report_Syslog="" #日志服务 ok
report_SNMP="" #SNMP OK
report_NTP="" #NTP ok
report_JDK="" #JDK版本 ok
function version(){
echo ""
echo ""
echo "系统巡检脚本：Version $VERSION"
}

function getCpuStatus(){
echo ""
echo ""
echo "############################ CPU检查 #############################"
Physical_CPUs=$(grep "physical id" /proc/cpuinfo| sort | uniq | wc -l)
Virt_CPUs=$(grep "processor" /proc/cpuinfo | wc -l)
CPU_Kernels=$(grep "cores" /proc/cpuinfo|uniq| awk -F ': ' '{print $2}')
CPU_Type=$(grep "model name" /proc/cpuinfo | awk -F ': ' '{print $2}' | sort | uniq)
CPU_Arch=$(uname -m)
echo "物理CPU个数:$Physical_CPUs"
echo "逻辑CPU个数:$Virt_CPUs"
echo "每CPU核心数:$CPU_Kernels"
echo " CPU型号:$CPU_Type"
echo " CPU架构:$CPU_Arch"
#报表信息
report_CPUs=$Virt_CPUs #CPU数量
report_CPUType=$CPU_Type #CPU类型
report_Arch=$CPU_Arch #CPU架构
}

function getMemStatus(){
echo ""
echo ""
echo "############################ 内存检查 ############################"
if [[ $centosVersion < 7 ]];then
free -mo
else
free -h
fi
#报表信息
MemTotal=$(grep MemTotal /proc/meminfo| awk '{print $2}') #KB
MemFree=$(grep MemFree /proc/meminfo| awk '{print $2}') #KB
let MemUsed=MemTotal-MemFree
MemPercent=$(awk "BEGIN {if($MemTotal==0){printf 100}else{printf \"%.2f\",$MemUsed*100/$MemTotal}}")
report_MemTotal="$((MemTotal/1024))""MB" #内存总容量(MB)
report_MemFree="$((MemFree/1024))""MB" #内存剩余(MB)
report_MemUsedPercent="$(awk "BEGIN {if($MemTotal==0){printf 100}else{printf \"%.2f\",$MemUsed*100/$MemTotal}}")""%" #内存使用率%
}
function getDiskStatus(){
echo ""
echo ""
echo "############################ 磁盘检查 ############################"
df -hiP | sed 's/Mounted on/Mounted/'> /tmp/inode
df -hTP | sed 's/Mounted on/Mounted/'> /tmp/disk 
join /tmp/disk /tmp/inode | awk '{print $1,$2,"|",$3,$4,$5,$6,"|",$8,$9,$10,$11,"|",$12}'| column -t
#报表信息
diskdata=$(df -TP | sed '1d' | awk '$2!="tmpfs"{print}') #KB
disktotal=$(echo "$diskdata" | awk '{total+=$3}END{print total}') #KB
diskused=$(echo "$diskdata" | awk '{total+=$4}END{print total}') #KB
diskfree=$((disktotal-diskused)) #KB
diskusedpercent=$(echo $disktotal $diskused | awk '{if($1==0){printf 100}else{printf "%.2f",$2*100/$1}}') 
inodedata=$(df -iTP | sed '1d' | awk '$2!="tmpfs"{print}')
inodetotal=$(echo "$inodedata" | awk '{total+=$3}END{print total}')
inodeused=$(echo "$inodedata" | awk '{total+=$4}END{print total}')
inodefree=$((inodetotal-inodeused))
inodeusedpercent=$(echo $inodetotal $inodeused | awk '{if($1==0){printf 100}else{printf "%.2f",$2*100/$1}}')
report_DiskTotal=$((disktotal/1024/1024))"GB" #硬盘总容量(GB)
report_DiskFree=$((diskfree/1024/1024))"GB" #硬盘剩余(GB)
report_DiskUsedPercent="$diskusedpercent""%" #硬盘使用率%
report_InodeTotal=$((inodetotal/1000))"K" #Inode总量
report_InodeFree=$((inodefree/1000))"K" #Inode剩余
report_InodeUsedPercent="$inodeusedpercent""%" #Inode使用率%

}

function getSystemStatus(){
echo ""
echo ""
echo "############################ 系统检查 ############################"
if [ -e /etc/sysconfig/i18n ];then
default_LANG="$(grep "LANG=" /etc/sysconfig/i18n | grep -v "^#" | awk -F '"' '{print $2}')"
else
default_LANG=$LANG
fi
export LANG="en_US.UTF-8"
Release=$(cat /etc/redhat-release 2>/dev/null)
Kernel=$(uname -r)
OS=$(uname -o)
Hostname=$(uname -n)
SELinux=$(/usr/sbin/sestatus | grep "SELinux status: " | awk '{print $3}')
LastReboot=$(who -b | awk '{print $3,$4}')
uptime=$(uptime | sed 's/.*up \([^,]*\), .*/\1/')
echo " 系统：$OS"
echo " 发行版本：$Release"
echo " 内核：$Kernel"
echo " 主机名：$Hostname"
echo " SELinux：$SELinux"
echo "语言/编码：$default_LANG"
echo " 当前时间：$(date +'%F %T')"
echo " 最后启动：$LastReboot"
echo " 运行时间：$uptime"
#报表信息
report_DateTime=$(date +"%F %T") #日期
report_Hostname="$Hostname" #主机名
report_OSRelease="$Release" #发行版本
report_Kernel="$Kernel" #内核
report_Language="$default_LANG" #语言/编码
report_LastReboot="$LastReboot" #最近启动时间
report_Uptime="$uptime" #运行时间（天）
report_Selinux="$SELinux"
export LANG="$default_LANG"

}

function getServiceStatus(){
echo ""
echo ""
echo "############################ 服务检查 ############################"
echo ""
if [[ $centosVersion > 7 ]];then
conf=$(systemctl list-unit-files --type=service --state=enabled --no-pager | grep "enabled")
process=$(systemctl list-units --type=service --state=running --no-pager | grep ".service")
#报表信息
report_SelfInitiatedService="$(echo "$conf" | wc -l)" #自启动服务数量
report_RuningService="$(echo "$process" | wc -l)" #运行中服务数量
else
conf=$(/sbin/chkconfig | grep -E ":on|:启用")
process=$(/sbin/service --status-all 2>/dev/null | grep -E "is running|正在运行")
#报表信息
report_SelfInitiatedService="$(echo "$conf" | wc -l)" #自启动服务数量
report_RuningService="$(echo "$process" | wc -l)" #运行中服务数量
fi
echo "服务配置"
echo "--------"
echo "$conf" | column -t
echo ""
echo "正在运行的服务"
echo "--------------"
echo "$process"

}


function getAutoStartStatus(){
echo ""
echo ""
echo "############################ 自启动检查 ##########################"
conf=$(grep -v "^#" /etc/rc.d/rc.local| sed '/^$/d')
echo "$conf"
#报表信息
report_SelfInitiatedProgram="$(echo $conf | wc -l)" #自启动程序数量
}

function getLoginStatus(){
echo ""
echo ""
echo "############################ 登录检查 ############################"
last | head
}

function getNetworkStatus(){
echo ""
echo ""
echo "############################ 网络检查 ############################"
if [[ $centosVersion < 7 ]];then
/sbin/ifconfig -a | grep -v packets | grep -v collisions | grep -v inet6
else
#ip a
for i in $(ip link | grep BROADCAST | awk -F: '{print $2}');do ip add show $i | grep -E "BROADCAST|global"| awk '{print $2}' | tr '\n' ' ' ;echo "" ;done
fi
GATEWAY=$(ip route | grep default | awk '{print $3}')
DNS=$(grep nameserver /etc/resolv.conf| grep -v "#" | awk '{print $2}' | tr '\n' ',' | sed 's/,$//')
echo ""
echo "网关：$GATEWAY "
echo " DNS：$DNS"
#报表信息
IP=$(ip -f inet addr | grep -v 127.0.0.1 | grep inet | awk '{print $NF,$2}' | tr '\n' ',' | sed 's/,$//')
MAC=$(ip link | grep -v "LOOPBACK\|loopback" | awk '{print $2}' | sed 'N;s/\n//' | tr '\n' ',' | sed 's/,$//')
report_IP="$IP" #IP地址
report_MAC=$MAC #MAC地址
report_Gateway="$GATEWAY" #默认网关
report_DNS="$DNS" #DNS
}

function getListenStatus(){
echo ""
echo ""
echo "############################ 监听检查 ############################"
TCPListen=$(ss -ntul | column -t)
echo "$TCPListen"
#报表信息
report_Listen="$(echo "$TCPListen"| sed '1d' | awk '/tcp/ {print $5}' | awk -F: '{print $NF}' | sort | uniq | wc -l)"
}

function getCronStatus(){
echo ""
echo ""
echo "############################ 计划任务检查 ########################"
Crontab=0
for shell in $(grep -v "/sbin/nologin" /etc/shells);do
for user in $(grep "$shell" /etc/passwd| awk -F: '{print $1}');do
crontab -l -u $user >/dev/null 2>&1
status=$?
if [ $status -eq 0 ];then
echo "$user"
echo "--------"
crontab -l -u $user
let Crontab=Crontab+$(crontab -l -u $user | wc -l)
echo ""
fi
done
done
#计划任务
find /etc/cron* -type f | xargs -i ls -l {} | column -t
let Crontab=Crontab+$(find /etc/cron* -type f | wc -l)
#报表信息
report_Crontab="$Crontab" #计划任务数
}
function getHowLongAgo(){
# 计算一个时间戳离现在有多久了
datetime="$*"
[ -z "$datetime" ] && echo "错误的参数：getHowLongAgo() $*"
Timestamp=$(date +%s -d "$datetime") #转化为时间戳
Now_Timestamp=$(date +%s)
Difference_Timestamp=$(($Now_Timestamp-$Timestamp))
days=0;hours=0;minutes=0;
sec_in_day=$((60*60*24));
sec_in_hour=$((60*60));
sec_in_minute=60
while (( $(($Difference_Timestamp-$sec_in_day)) > 1 ))
do
let Difference_Timestamp=Difference_Timestamp-sec_in_day
let days++
done
while (( $(($Difference_Timestamp-$sec_in_hour)) > 1 ))
do
let Difference_Timestamp=Difference_Timestamp-sec_in_hour
let hours++
done
echo "$days 天 $hours 小时前"
}

function getUserLastLogin(){
# 获取用户最近一次登录的时间，含年份
# 很遗憾last命令不支持显示年份，只有"last -t YYYYMMDDHHMMSS"表示某个时间之间的登录，我
# 们只能用最笨的方法了，对比今天之前和今年元旦之前（或者去年之前和前年之前……）某个用户
# 登录次数，如果登录统计次数有变化，则说明最近一次登录是今年。
username=$1
: ${username:="`whoami`"}
thisYear=$(date +%Y)
oldesYear=$(last | tail -n1 | awk '{print $NF}')
while(( $thisYear >= $oldesYear));do
loginBeforeToday=$(last $username | grep $username | wc -l)
loginBeforeNewYearsDayOfThisYear=$(last $username -t $thisYear"0101000000" | grep $username | wc -l)
if [ $loginBeforeToday -eq 0 ];then
echo "从未登录过"
break
elif [ $loginBeforeToday -gt $loginBeforeNewYearsDayOfThisYear ];then
lastDateTime=$(last -i $username | head -n1 | awk '{for(i=4;i<(NF-2);i++)printf"%s ",$i}')" $thisYear" #格式如: Sat Nov 2 20:33 2015
lastDateTime=$(date "+%Y-%m-%d %H:%M:%S" -d "$lastDateTime")
echo "$lastDateTime"
break
else
thisYear=$((thisYear-1))
fi
done

}

function getUserStatus(){
echo ""
echo ""
echo "############################ 用户检查 ############################"
#/etc/passwd 最后修改时间
pwdfile="$(cat /etc/passwd)"
Modify=$(stat /etc/passwd | grep Modify | tr '.' ' ' | awk '{print $2,$3}')

echo "/etc/passwd 最后修改时间：$Modify ($(getHowLongAgo $Modify))"
echo ""
echo "特权用户"
echo "--------"
RootUser=""
for user in $(echo "$pwdfile" | awk -F: '{print $1}');do
if [ $(id -u $user) -eq 0 ];then
echo "$user"
RootUser="$RootUser,$user"
fi
done
echo ""
echo "用户列表"
echo "--------"
USERs=0
echo "$(
echo "用户名 UID GID HOME SHELL 最后一次登录"
for shell in $(grep -v "/sbin/nologin" /etc/shells);do
for username in $(grep "$shell" /etc/passwd| awk -F: '{print $1}');do
userLastLogin="$(getUserLastLogin $username)"
echo "$pwdfile" | grep -w "$username" |grep -w "$shell"| awk -F: -v lastlogin="$(echo "$userLastLogin" | tr ' ' '_')" '{print $1,$3,$4,$6,$7,lastlogin}'
done
let USERs=USERs+$(echo "$pwdfile" | grep "$shell"| wc -l)
done
)" | column -t
echo ""
echo "空密码用户"
echo "----------"
USEREmptyPassword=""
for shell in $(grep -v "/sbin/nologin" /etc/shells);do
for user in $(echo "$pwdfile" | grep "$shell" | cut -d: -f1);do
r=$(awk -F: '$2=="!!"{print $1}' /etc/shadow | grep -w $user)
if [ ! -z $r ];then
echo $r
USEREmptyPassword="$USEREmptyPassword,"$r
fi
done 
done
echo ""
echo "相同ID的用户"
echo "------------"
USERTheSameUID=""
UIDs=$(cut -d: -f3 /etc/passwd | sort | uniq -c | awk '$1>1{print $2}')
for uid in $UIDs;do
echo -n "$uid";
USERTheSameUID="$uid"
r=$(awk -F: 'ORS="";$3=='"$uid"'{print ":",$1}' /etc/passwd)
echo "$r"
echo ""
USERTheSameUID="$USERTheSameUID $r,"
done
#报表信息
report_USERs="$USERs" #用户
report_USEREmptyPassword=$(echo $USEREmptyPassword | sed 's/^,//') 
report_USERTheSameUID=$(echo $USERTheSameUID | sed 's/,$//') 
report_RootUser=$(echo $RootUser | sed 's/^,//') #特权用户
}


function getPasswordStatus {
echo ""
echo ""
echo "############################ 密码检查 ############################"
pwdfile="$(cat /etc/passwd)"
echo ""
echo "密码过期检查"
echo "------------"
result=""
for shell in $(grep -v "/sbin/nologin" /etc/shells);do
for user in $(echo "$pwdfile" | grep "$shell" | cut -d: -f1);do
get_expiry_date=$(/usr/bin/chage -l $user | grep 'Password expires' | cut -d: -f2)
if [[ $get_expiry_date = ' never' || $get_expiry_date = 'never' ]];then
printf "%-15s 永不过期\n" $user
result="$result,$user:never"
else
password_expiry_date=$(date -d "$get_expiry_date" "+%s")
current_date=$(date "+%s")
diff=$(($password_expiry_date-$current_date))
let DAYS=$(($diff/(60*60*24)))
printf "%-15s %s天后过期\n" $user $DAYS
result="$result,$user:$DAYS days"
fi
done
done
report_PasswordExpiry=$(echo $result | sed 's/^,//')

echo ""
echo "密码策略检查"
echo "------------"
grep -v "#" /etc/login.defs | grep -E "PASS_MAX_DAYS|PASS_MIN_DAYS|PASS_MIN_LEN|PASS_WARN_AGE"


}

function getSudoersStatus(){
echo ""
echo ""
echo "############################ Sudoers检查 #########################"
conf=$(grep -v "^#" /etc/sudoers| grep -v "^Defaults" | sed '/^$/d')
echo "$conf"
echo ""
#报表信息
report_Sudoers="$(echo $conf | wc -l)"
}

function getInstalledStatus(){
echo ""
echo ""
echo "############################ 软件检查 ############################"
rpm -qa --last | head | column -t 
}

function getProcessStatus(){
echo ""
echo ""
echo "############################ 进程检查 ############################"
if [ $(ps -ef | grep defunct | grep -v grep | wc -l) -ge 1 ];then
echo ""
echo "僵尸进程";
echo "--------"
ps -ef | head -n1
ps -ef | grep defunct | grep -v grep
fi
echo ""
echo "内存占用TOP10"
echo "-------------"
echo -e "PID %MEM RSS COMMAND
$(ps aux | awk '{print $2, $4, $6, $11}' | sort -k3rn | head -n 10 )"| column -t 
echo ""
echo "CPU占用TOP10"
echo "------------"
top b -n1 | head -17 | tail -11
#报表信息
report_DefunctProsess="$(ps -ef | grep defunct | grep -v grep|wc -l)"
}

function getJDKStatus(){
echo ""
echo ""
echo "############################ JDK检查 #############################"
java -version 2>/dev/null
if [ $? -eq 0 ];then
java -version 2>&1
fi
echo "JAVA_HOME=\"$JAVA_HOME\""
#报表信息
report_JDK="$(java -version 2>&1 | grep version | awk '{print $1,$3}' | tr -d '"')"
}
function getSyslogStatus(){
echo ""
echo ""
echo "############################ syslog检查 ##########################"
echo "服务状态：$(getState rsyslog)"
echo ""
echo "/etc/rsyslog.conf"
echo "-----------------"
cat /etc/rsyslog.conf 2>/dev/null | grep -v "^#" | grep -v "^\\$" | sed '/^$/d' | column -t
#报表信息
report_Syslog="$(getState rsyslog)"
}
function getFirewallStatus(){
echo ""
echo ""
echo "############################ 防火墙检查 ##########################"
#防火墙状态，策略等
if [[ $centosVersion < 7 ]];then
/etc/init.d/iptables status >/dev/null 2>&1
status=$?
if [ $status -eq 0 ];then
s="active"
elif [ $status -eq 3 ];then
s="inactive"
elif [ $status -eq 4 ];then
s="permission denied"
else
s="unknown"
fi
else
s="$(getState iptables)"
fi
echo "iptables: $s"
echo ""
echo "/etc/sysconfig/iptables"
echo "-----------------------"
cat /etc/sysconfig/iptables 2>/dev/null
#报表信息
report_Firewall="$s"
}

function getSNMPStatus(){
#SNMP服务状态，配置等
echo ""
echo ""
echo "############################ SNMP检查 ############################"
status="$(getState snmpd)"
echo "服务状态：$status"
echo ""
if [ -e /etc/snmp/snmpd.conf ];then
echo "/etc/snmp/snmpd.conf"
echo "--------------------"
cat /etc/snmp/snmpd.conf 2>/dev/null | grep -v "^#" | sed '/^$/d'
fi
#报表信息
report_SNMP="$(getState snmpd)"
}



function getState(){
if [[ $centosVersion < 7 ]];then
if [ -e "/etc/init.d/$1" ];then
if [ `/etc/init.d/$1 status 2>/dev/null | grep -E "is running|正在运行" | wc -l` -ge 1 ];then
r="active"
else
r="inactive"
fi
else
r="unknown"
fi
else
#CentOS 7+
r="$(systemctl is-active $1 2>&1)"
fi
echo "$r"
}

function getSSHStatus(){
#SSHD服务状态，配置,受信任主机等
echo ""
echo ""
echo "############################ SSH检查 #############################"
#检查受信任主机
pwdfile="$(cat /etc/passwd)"
echo "服务状态：$(getState sshd)"
Protocol_Version=$(cat /etc/ssh/sshd_config | grep Protocol | awk '{print $2}')
echo "SSH协议版本：$Protocol_Version"
echo ""
echo "信任主机"
echo "--------"
authorized=0
for user in $(echo "$pwdfile" | grep /bin/bash | awk -F: '{print $1}');do
authorize_file=$(echo "$pwdfile" | grep -w $user | awk -F: '{printf $6"/.ssh/authorized_keys"}')
authorized_host=$(cat $authorize_file 2>/dev/null | awk '{print $3}' | tr '\n' ',' | sed 's/,$//')
if [ ! -z $authorized_host ];then
echo "$user 授权 \"$authorized_host\" 无密码访问"
fi
let authorized=authorized+$(cat $authorize_file 2>/dev/null | awk '{print $3}'|wc -l)
done

echo ""
echo "是否允许ROOT远程登录"
echo "--------------------"
config=$(cat /etc/ssh/sshd_config | grep PermitRootLogin)
firstChar=${config:0:1}
if [ $firstChar == "#" ];then
PermitRootLogin="yes" #默认是允许ROOT远程登录的
else
PermitRootLogin=$(echo $config | awk '{print $2}')
fi
echo "PermitRootLogin $PermitRootLogin"

echo ""
echo "/etc/ssh/sshd_config"
echo "--------------------"
cat /etc/ssh/sshd_config | grep -v "^#" | sed '/^$/d'

#报表信息
report_SSHAuthorized="$authorized" #SSH信任主机
report_SSHDProtocolVersion="$Protocol_Version" #SSH协议版本
report_SSHDPermitRootLogin="$PermitRootLogin" #允许root远程登录
}
function getNTPStatus(){
#NTP服务状态，当前时间，配置等
echo ""
echo ""
echo "############################ NTP检查 #############################"
if [ -e /etc/ntp.conf ];then
echo "服务状态：$(getState ntpd)"
echo ""
echo "/etc/ntp.conf"
echo "-------------"
cat /etc/ntp.conf 2>/dev/null | grep -v "^#" | sed '/^$/d'
fi
#报表信息
report_NTP="$(getState ntpd)"
}


function uploadHostDailyCheckReport(){
json="{
\"DateTime\":\"$report_DateTime\",
\"Hostname\":\"$report_Hostname\",
\"OSRelease\":\"$report_OSRelease\",
\"Kernel\":\"$report_Kernel\",
\"Language\":\"$report_Language\",
\"LastReboot\":\"$report_LastReboot\",
\"Uptime\":\"$report_Uptime\",
\"CPUs\":\"$report_CPUs\",
\"CPUType\":\"$report_CPUType\",
\"Arch\":\"$report_Arch\",
\"MemTotal\":\"$report_MemTotal\",
\"MemFree\":\"$report_MemFree\",
\"MemUsedPercent\":\"$report_MemUsedPercent\",
\"DiskTotal\":\"$report_DiskTotal\",
\"DiskFree\":\"$report_DiskFree\",
\"DiskUsedPercent\":\"$report_DiskUsedPercent\",
\"InodeTotal\":\"$report_InodeTotal\",
\"InodeFree\":\"$report_InodeFree\",
\"InodeUsedPercent\":\"$report_InodeUsedPercent\",
\"IP\":\"$report_IP\",
\"MAC\":\"$report_MAC\",
\"Gateway\":\"$report_Gateway\",
\"DNS\":\"$report_DNS\",
\"Listen\":\"$report_Listen\",
\"Selinux\":\"$report_Selinux\",
\"Firewall\":\"$report_Firewall\",
\"USERs\":\"$report_USERs\",
\"USEREmptyPassword\":\"$report_USEREmptyPassword\",
\"USERTheSameUID\":\"$report_USERTheSameUID\",
\"PasswordExpiry\":\"$report_PasswordExpiry\",
\"RootUser\":\"$report_RootUser\",
\"Sudoers\":\"$report_Sudoers\",
\"SSHAuthorized\":\"$report_SSHAuthorized\",
\"SSHDProtocolVersion\":\"$report_SSHDProtocolVersion\",
\"SSHDPermitRootLogin\":\"$report_SSHDPermitRootLogin\",
\"DefunctProsess\":\"$report_DefunctProsess\",
\"SelfInitiatedService\":\"$report_SelfInitiatedService\",
\"SelfInitiatedProgram\":\"$report_SelfInitiatedProgram\",
\"RuningService\":\"$report_RuningService\",
\"Crontab\":\"$report_Crontab\",
\"Syslog\":\"$report_Syslog\",
\"SNMP\":\"$report_SNMP\",
\"NTP\":\"$report_NTP\",
\"JDK\":\"$report_JDK\"
}"
#echo "$json" 
curl -l -H "Content-type: application/json" -X POST -d "$json" "$uploadHostDailyCheckReportApi" 2>/dev/null
}

function getchage_file_24h()
{
echo "############################ 文件检查 #############################"
    check2=$(find / -name '*.sh' -mtime -1)
check21=$(find / -name '*.asp' -mtime -1)
check22=$(find / -name '*.php' -mtime -1)
check23=$(find / -name '*.aspx' -mtime -1)
check24=$(find / -name '*.jsp' -mtime -1)
check25=$(find / -name '*.html' -mtime -1)
check26=$(find / -name '*.htm' -mtime -1)
check9=$(find / -name core -exec ls -l {} \;)
check10=$(cat /etc/crontab)
check12=$(ls -alt /usr/bin | head -10)
cat <<EOF

############################查看所有被修改过的文件返回最近24小时内的############################
${check2}
${check21}
${check22}
${check23}
${check24}
${check25}
${check26}
${line}

############################检查定时文件的完整性############################
${check10}
${line}

############################查看系统命令是否被替换############################
${check12}
${line}
EOF
}

function check(){
version
getSystemStatus
getCpuStatus
getMemStatus
getDiskStatus
getNetworkStatus
getListenStatus
getProcessStatus
getServiceStatus
getAutoStartStatus
getLoginStatus
getCronStatus
getUserStatus
getPasswordStatus
getSudoersStatus
getJDKStatus
getFirewallStatus
getSSHStatus
getSyslogStatus
getSNMPStatus
getNTPStatus
getInstalledStatus
getchage_file_24h
}


#执行检查并保存检查结果
check > $RESULTFILE

echo "检查结果：$RESULTFILE"
}

#13.数据库备份
backupsql(){
USER="root"
#数据库密码
PASSWORD="root123"
#数据库
DATABASE="ywtg_new"
#ip
HOSTNAME="localhost"
#备份目录
BACKUP_DIR=./ywtg/backup/
#日志文件
LOGFILE=./ywtg/backup/ywtg_backup.log
#时间格式
DATE=`date '+%Y%m%d-%H%M'`
#DATE=`date '+%Y%m%d-%H%M'`
#备份文件
DUMPFILE='ywtg'-$DATE.sql
#压缩文件
ARCHIVE='ywtg'-$DATE.sql.tgz
#组装dump命令
OPTIONS="-h$HOSTNAME -u$USER -p$PASSWORD $DATABASE"

#判断备份文件存储目录是否存在，否则创建该目录
if [ ! -d $BACKUP_DIR ] ;
then
        mkdir -p "$BACKUP_DIR"
fi

#开始备份之前，将备份信息头写入日记文件
echo " " >> $LOGFILE
echo " " >> $LOGFILE
echo "------------------" >> $LOGFILE
echo "BACKUP DATE:" $(date +"%y-%m-%d %H:%M:%S") >> $LOGFILE
echo "------------------" >> $LOGFILE

#切换至备份目录
cd $BACKUP_DIR
#使用mysqldump 命令备份制定数据库，并以格式化的时间戳命名备份文件
/usr/local/mysql/bin/mysqldump $OPTIONS > $DUMPFILE
#判断数据库备份是否成功
if [[ $? == 0 ]]; then
    #创建备份文件的压缩包
    tar czvf $ARCHIVE $DUMPFILE >> $LOGFILE 2>&1
    #输入备份成功的消息到日记文件
    echo "[$ARCHIVE] Backup Successful!" >> $LOGFILE
    #删除原始备份文件，只需保 留数据库备份文件的压缩包即可
    rm -f $DUMPFILE
else
    echo "Database Backup Fail!" >> $LOGFILE
fi
#输出备份过程结束的提醒消息
echo "Backup Process Done"
#删除7天以上的备份
find /home/ywtg/backup/  -type f -mtime +7 -exec rm {} ;
}

#14.禁异常IP
banip(){
####################################################################################
#根据web访问日志，封禁请求量异常的IP，如IP在半小时后恢复正常，则解除封禁
####################################################################################
logfile=./banip/log/access.log
#显示一分钟前的小时和分钟
d1=`date -d "-1 minute" +%H%M`
d2=`date +%M`
ipt=/sbin/iptables
ips=/tmp/ips.txt
block()
{ 
#将一分钟前的日志全部过滤出来并提取IP以及统计访问次数
 grep '$d1:' $logfile|awk '{print $1}'|sort -n|uniq -c|sort -n > $ips
 #利用for循环将次数超过100的IP依次遍历出来并予以封禁
 for i in `awk '$1>100 {print $2}' $ips` 
 do
 $ipt -I INPUT -p tcp --dport 80 -s $i -j REJECT 
 echo "`date +%F-%T` $i" >> /tmp/badip.log 
 done
}
unblock()
{ 
#将封禁后所产生的pkts数量小于10的IP依次遍历予以解封
 for a in `$ipt -nvL INPUT --line-numbers |grep '0.0.0.0/0'|awk '$2<10 {print $1}'|sort -nr` 
 do 
 $ipt -D INPUT $a
 done
 $ipt -Z
}
#当时间在00分以及30分时执行解封函数
if [ $d2 -eq "00" ] || [ $d2 -eq "30" ] 
 then
 #要先解再封，因为刚刚封禁时产生的pkts数量很少
 unblock
 block 
 else
 block
fi
}

#15.一键安装LNMP环境
LNMPinstall(){
NGINX_V=1.22.1
PHP_V=5.6.36
TMP_DIR=/tmp

INSTALL_DIR=/usr/local

PWD_C=$PWD

echo
echo -e "\tMenu\n"
echo -e "1. Install Nginx"
echo -e "2. Install PHP"
echo -e "3. Install MySQL"
echo -e "4. Deploy LNMP"
echo -e "9. Quit"

function command_status_check() {
        if [ $? -ne 0 ]; then
                echo $1
                exit
        fi
}

function install_nginx() {
cat <<EOF > /etc/yum.repos.d/nginx.repo
[nginx-stable]
name=nginx stable repo
baseurl=http://nginx.org/packages/centos/\$releasever/\$basearch/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true
EOF
yum makecache fast && yum install -y nginx-$NGINX_V
systemctl start nginx  && systemctl status nginx && echo "NGINX已安装并启动"
}


function install_php() {
        cd $TMP_DIR
    yum install -y gcc gcc-c++ make gd-devel libxml2-devel \
        libcurl-devel libjpeg-devel libpng-devel openssl-devel \
        libmcrypt-devel libxslt-devel libtidy-devel
    wget [url=http://docs.php.net/distributions/php-]http://docs.php.net/distributions/php-[/url]${PHP_V}.tar.gz
    tar zxf php-${PHP_V}.tar.gz
    cd php-${PHP_V}
    ./configure --prefix=$INSTALL_DIR/php \
    --with-config-file-path=$INSTALL_DIR/php/etc \
    --enable-fpm --enable-opcache \
    --with-mysql --with-mysqli --with-pdo-mysql \
    --with-openssl --with-zlib --with-curl --with-gd \
    --with-jpeg-dir --with-png-dir --with-freetype-dir \
    --enable-mbstring --enable-hash
    command_status_check "PHP - 平台环境检查失败！"
    make -j 4
    command_status_check "PHP - 编译失败！"
    make install
    command_status_check "PHP - 安装失败！"
    cp php.ini-production $INSTALL_DIR/php/etc/php.ini
    cp sapi/fpm/php-fpm.conf $INSTALL_DIR/php/etc/php-fpm.conf
    cp sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm
    chmod +x /etc/init.d/php-fpm
    /etc/init.d/php-fpm start
    command_status_check "PHP - 启动失败！"
}

read -p "请输入编号：" number
case $number in
    1)
        install_nginx;;
    2)
        install_php;;
    3)
        install_mysql;;
    4)
        install_nginx
        install_php
        ;;
    9)
        exit;;
esac
}


# 主程序入口
menu1

