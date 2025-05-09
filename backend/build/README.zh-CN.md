<p style="text-align: center;">
    <a href="https://www.51bbz.com">
        <img src="https://static.dingtalk.com/media/lAHPDefSAchf8RnNASzNASw_300_300.gif?bizType=im" width="40%"  alt=""/>
    </a>
</p>


# **CI/CD 脚本目录概述**

_本文档描述了不同环境下的 CI/CD 脚本。_
\[ 中文 | [English](README.md) \]

### 目录结构
```
├── build #CI\CD脚本目录
│     ├── beta #测试环境
│     │     ├── uat_fat #公测|预发环境独立构建部署
│     │     │     ├── build-beta.sh
│     │     │     └── deploy-beta.sh
│     │     └── uat_one_click #预发环境全量构建部署
│     │         ├── build-all-uat.sh
│     │         ├── deploy-all-uat.sh
│     │         ├── update-app.sh
│     │         └── update-item.sh
│     ├── prod
│     │     ├── prod_one_click #生产环境全量构建部署
│     │     │     ├── build-all-prod.sh
│     │     │     ├── control.sh
│     │     │     ├── deploy-all-prod.sh
│     │     │     └── update-item.sh
│     │     └── prod_separate #生产环境独立构建部署
│     │         ├── build-prod.sh
│     │         └── deploy-prod.sh
│     ├── README.md
│     └── README.zh-CN.md
├── CHANGELOG.md
```

## 1. 公测|预发环境

**脚本:**

- **build-beta.sh ----编译机(1)**
- **deploy-beta.sh ----部署发布机(2)**

**用途:**

- 供开发人员快速部署到公测和预发环境。

**触发条件:**

### 开发人员输入 **[build-$env]$item-$app--$version**
- **Ps**：
- 1.**interface|admin|web**(使用)**`bbx`|`bbz`**(作为)**$item**
- 2.**account|communal|content|project|finance|operation|marketing|mall|iam**(使用)**`main`**(作为)**$item**
- 3.**im|infra|**(使用)**`common`**(作为)**$item**
- 例: **[build-public]bbx-interface--v1.1.0**
- 例: **[build-public]main-account--v1.1.0**
- 例: **[build-rc]common-infra--v1.1.0**
- 例: **[build-rc]bbz-admin--v1.1.0**

---

## 2. 预发环境（全量发布）

**脚本:**

- **build-all-uat.sh ----编译机(1)**
- **deploy-all-uat.sh ----部署发布机(2)**
- **update-app.sh ----预发布更新容器**
- **update-item.sh ----预发布更新项目**

**用途:**

- 用于全量更新发布到预发环境。

**触发条件:**

###  终端命令行进入指定目录,输入 **./build-all-uat.sh**

---

## 3. 生产环境（补丁版本）

**脚本:**

- **build-prod.sh ----编译机(1)**
- **deploy-prod.sh ----部署发布机(2)**

**用途:**

- 通常用于对生产环境中的单个服务进行快速更新。

**触发条件:**

### 管理员或开发人员输入 **[buildonline-online]$item-$app--$version**
- **Ps**：
- 1.**interface|admin|web**(使用)**`bbx`|`bbz`**(作为)**$item**
- 2.**account|communal|content|project|finance|operation|marketing|mall|iam**(使用)**`main`**(作为)**$item**
- 3.**im|infra|**(使用)**`common`**(作为)**$item**
- 例: **[buildonline-online]bbx-interface--v1.1.0**
- 例: **[buildonline-online]bbz-admin--v1.1.0**
- 例: **[buildonline-online]main-account--v1.1.0**
- 例: **[buildonline-online]common-infra--v1.1.0**

---

## 4. 生产环境（全量发布）

**脚本:**

- **control.sh  ----部署人员本地机(1)**
- **build-all-prod.sh  ----编译机(2)**
- **deploy-all-prod.sh ----部署发布机(3)**
- **update-item.sh ----正式发布更新项目**

**用途:**

- 用于全量更新发布到生产环境。

**触发条件:**

###  终端命令行进入指定目录,输入 **./control.sh**。

---

## 变量和相关说明

- **`$build`**：代码推送的构建属性。
- **`$env`**：构建部署的环境（例如 public, rc, online）。
- **`$item`**：构建的项目（例如 bbx, bbz）。
- **`$version`**：构建版本（例如 v1.1.0）。

**注意:**
- 每次更新时，请先将修改内容提交至代码仓库，并附上详细的修改记录（如通过 git commit 提交信息描述改动内容）。
- 在完成代码推送后，请前往项目目录的 CHANGELOG.md 文件中补充本次更新的具体事项，包括但不限于：
- 1.新增功能
- 2.修复的缺陷
- 3.已知问题或限制
- 4.确保更新内容清晰、简洁，并按照触发要求进行构建操作。
- 对于生产环境的构建操作，请务必提前通知技术负责人或运维团队。
---
- 本地构建服务器（254）在 **local-info.sh** 中存储构建所需的基本信息，包括 `$build`、`$env`、`$item`、`$version` 和敏感信息(其不随项目上传至代码仓库)
- 生产环境远程服务器（237）在 **local_prod_info.sh**中存储构建所需的基本信息，包括 `$build`、`$env`、`$item`、`$version` 和敏感信息(其不随项目上传至代码仓库)




