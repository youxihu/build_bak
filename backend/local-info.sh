commit_message=$(git log -1 --no-merges --pretty=%B)
presenter=$(git log -1 --no-merges --pretty="%an")
read -r build envior app version <<<$(echo "$commit_message" | awk -F '[][ -]+' '{print $2, $3, $4, $5}')
desip="192.168.2.254:54800"
husr="nx-cicd-jenkins"
hpasswd="8a6cf90e2a2ab16a@bbx"
admin="9900"
account="9001"
content="9002"
finance="9005"
operation="9007"
file="9006"
core="2000"
project="9003"
auth="9004"
marketing="9008"
web="8900"
interface="8800"
communal="2000"

