commit_message=$(git log -1 --no-merges --pretty=%B)
presenter=$(git log -1 --no-merges --pretty="%an")
read -r build environ version <<<$(echo "$commit_message" | awk -F '[][ -]+' '{print $2, $3,$4}')
# 定义镜像仓库信息
repo_addr="192.168.2.254:54800"
repo_user="nx-cicd-jenkins"
repo_passwd="8a6cf90e2a2ab16a@bbx"
NUXT_API_SERVER_URL="biaobiaoxing.com"
NUXT_BASE_URL="/webapi"