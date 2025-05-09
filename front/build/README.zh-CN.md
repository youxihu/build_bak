<p style="text-align: center;">
    <a href="https://51bbz.com">
        <img src="https://static.dingtalk.com/media/lAHPDefSAchf8RnNASzNASw_300_300.gif?bizType=im" width="40%"  alt=""/>
    </a>
</p>


# **前端官网 CI/CD 脚本目录概述**

_本文档描述了不同环境下的 CI/CD 脚本。_
\[ 中文 | [English](README.md) \]

### 目录结构
```
├── build #CI\CD脚本目录
│     ├── beta #测试环境
│     │     └── deploy-deploy.sh #公测预发环境构建部署脚本
│     ├── prod
│     │     ├── build-prod.sh    #正式环境构建脚本
│     │     └── deploy-prod.sh   #正式环境部署脚本
│     ├── README.md
│     └── README.zh-CN.md
├── CHANGELOG.md                
```

## 1. 公测|预发环境

**脚本:**

- **build-deploy.sh ----因公测和预发环境在本地服务器,将CI/CD流程简化**

**用途:**

- 供开发人员快速部署到公测和预发环境。

**触发条件:**

### 开发人员输入 **[build-$env]$version**
- **Ps**：
- 例: **[build-public]v1.1.0**
- 镜像名: public-galaxy-pc-nuxt3:v1.1.0
- 例: **[build-rc]v1.1.0**
- 镜像名: rc-galaxy-pc-nuxt3:v1.1.0


---
## 2. 生产环境

**脚本:**

- **build-prod.sh ----编译机(1)**
- **deploy-prod.sh ----部署发布机(2)**

**用途:**

- 用于对生产环境中的官网进行快速更新。

**触发条件:**

### 管理员或开发人员输入 **[buildonline-online]$version**
- **Ps**：
- 例: **[buildonline-online]v1.1.0**
- 镜像名: online-galaxy-pc-nuxt3:v1.1.0

---


## 变量和相关说明

- **`$build`**：代码推送的构建属性。
- **`$version`**：构建版本（例如 v1.1.0）。

**注意:**
- 每次更新时，请先将修改内容提交至代码仓库，并附上详细的修改记录（如通过 git commit 提交信息描述改动内容）。
- 在完成代码推送后，请前往 [CHANGELOG.md](../CHANGELOG.md) 文件中补充本次更新的具体事项，包括但不限于：
- 1.新增功能
- 2.修复的缺陷
- 3.已知问题或限制
- 4.确保更新内容清晰、简洁，并按照触发要求进行构建操作。
- 对于生产环境的构建操作，请务必提前通知技术负责人或运维团队。
---
- 本地构建服务器（254）在工作目录下的 **node-local-info.sh** 中存储构建所需的基本信息，包括 `$build`、`$env`、`$version` 和敏感信息(其不随项目上传至代码仓库)
- 生产环境远程服务器（237）在工作目录下的 **node-local-info.sh**中存储构建所需的基本信息，包括 `$build`、`$env`、`$version` 和敏感信息(其不随项目上传至代码仓库)




