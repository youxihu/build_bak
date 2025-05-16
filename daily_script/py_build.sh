!/bin/bash
#此脚本为python项目CICD自动化脚本
#创建一个本地脚本 pyload-env.sh,将关键变量传输到远程服务器上的/bbx/jenkins-env目录中
#通过 git pull 命令从远程仓库拉取最新的代码。
#如果拉取代码失败,则输出错误信息,发送钉钉消息和邮件通知相关人员,并退出脚本执行。
#打开错误检测模式，即如果任何命令执行失败，脚本将立即退出。
#定义了两个函数 build_supreme_sys_django 和 build_xj_projects,分别用于构建 supreme-sys-django模块和以xj-开头的其他模块
#在执行构建之前,根据应用名称进行分发：
#如果应用名称为 supreme-sys-django.则调用 build_supreme_sys_django 函数进行构建。
#如果应用名称以 xj- 开头，则调用 build_xj_projects 函数进行构建。
#如果无法匹配到正确的应用名称，则输出错误信息并退出脚本执行。
#执行构建操作时,会切换到相应的工作目录，运行 python setup.py sdist bdist_wheel 命令生成源码和构建包，并使用 twine upload 命令将构建好的包上传到指定的远程仓库。
#将pyload-env.sh 脚本传输到远程服务器的 /bbx/jenkins-env 目录,并通过SSH执行远程脚本 pyssh254.sh
#版本更新规则[build]xj-user--1.0.0

#设置工作目录等必备变量
work_dir="/jenkins/pydevops"
commit_message=$(git log -1 --no-merges --pretty=%B)
build=$(echo "$commit_message" | sed -E 's/^\[([^]]+)\].*/\1/')
app=$(echo "$commit_message" | sed 's/\[build\]//g' | awk -F"--" '{print $1}')
version=$(echo "$commit_message" | sed 's/\[build\]//g' | awk -F"--" '{print $2}')

#传输变量固定值到远程服务器的本地脚本
cat <<EOF >$work_dir/build/pyload-env.sh
export commit_message="$commit_message"
export build="$build"
export app="$app"
export version="$version"
EOF

# 切换到工作目录下的实际工作模块
cd "$work_dir/$app" && echo "切换工作目录成功" || { echo "切换工作目录失败"; exit 1; }

# 拉取最新代码
if ! git pull origin master; then
    echo "代码拉取失败，请联系开发和运维查看 GitLab 上传情况或脚本"
    sendDingDing ""$NIU": git pull 失败 请查看jenkins构建日志或检查是否缺少环境依赖"
    exit 1
fi

set -e
build_supreme_sys_django() {
    cd "$work_dir/supreme-sys-django"
    rm -rf dist/  build/
    python setup.py sdist bdist_wheel && twine upload -r bbx dist/*
    scp $work_dir/build/pyload-env.sh  bbx254:/bbx/jenkins-env/python
    scp $work_dir/build/pyssh254.sh  bbx254:/bbx/jenkins-env/python
    ssh bbx254 "bash /bbx/jenkins-env/python/pyssh254.sh"
}

build_xj_projects() {
    cd "$work_dir/$app"
    rm -rf dist/  build/
    python setup.py sdist bdist_wheel && twine upload -r bbx dist/*
    scp $work_dir/build/pyload-env.sh  bbx254:/bbx/jenkins-env/python
    scp $work_dir/build/pyssh254.sh  bbx254:/bbx/jenkins-env/python
    ssh bbx254 "bash /bbx/jenkins-env/python/pyssh254.sh"
}

# 构建操作分发
if [[ "$build" == "build" ]]; then
    case $app in
        supreme-sys-django)
            build_supreme_sys_django
            ;;
        xj-*)
            build_xj_project "$app"
            ;;
        *)
            echo "无法匹配版本类型：$app"
            exit 1
            ;;
    esac
fi
