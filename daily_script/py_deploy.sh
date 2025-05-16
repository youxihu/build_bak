#!/bin/bash

# 导入环境变量
source /bbx/jenkins-env/python/pyload-env.sh

# 切换到虚拟环境
cd /www/pythonvenv/bid-public-testing/ && source bin/activate

# 安装指定版本的模块
pip install "$app==$version"

# 重启supervisor进程
supervisorctl restart bid-public-testing

# 检查模块版本并发送钉钉消息
installed_version=$(pip list | grep -E "^$app " | awk '{print $2}')
if [ "$installed_version" == "$version" ]; then
  message="$NIU: $app 模块启动成功，已在测试服务器上启动"
else
  message="$NIU: $app 版本不一致，请登录服务器查看"
fi
sendDingDing "$message"

