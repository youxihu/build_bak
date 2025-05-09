<p style="text-align: center;">
    <a href="https://www.biaobiaoxing.com">
        <img src="https://static.dingtalk.com/media/lAHPDeREW3b-AzvNASzNASw_300_300.gif" width="40%"  alt=""/>
    </a>
</p>

# CI/CD Scripts Overview

_This document describes the CI/CD scripts for different environments._
\[ [中文](README.zh-CN.md) | English \]

### Directory Structure
```
├── build #Scripts Overview
│   ├── beta  #Open Beta Environment
│   │   ├── uat_fat  #Public Testing | Pre-release Env  Build and Deployment
│   │   │   ├── build-beta.sh
│   │   │   └── deploy-beta.sh
│   │   └── uat_one_click  #Pre-release Env Full Build and Deployment
│   │       ├── build-all-uat.sh
│   │       ├── deploy-all-uat.sh
│   │       ├── update-app.sh
│   │       └── update-item.sh
│   ├── prod
│   │   ├── prod_one_click #Prod Env Full Build and Deployment
│   │   │   ├── build-all-prod.sh
│   │   │   ├── control.sh
│   │   │   ├── deploy-all-prod.sh
│   │   │   └── update-item.sh
│   │   └── prod_separate #Prod Env Build and Deployment
│   │       ├── build-prod.sh
│   │       └── deploy-prod.sh
│   ├── README.md
│   └── README.zh-CN.md
├── CHANGELOG.md #Prod Env Full Build and Deployment Endorsement
```

## 1. Public Testing | Pre-release Environment

**Scripts:**

- **build-beta.sh ---- Build Machine (1)**
- **deploy-beta.sh ---- Deployment Machine (2)**

**Purpose:**

- To allow developers to quickly deploy to public testing and pre-release environments.

**Trigger Conditions:**

### Developers input **[build-$env]$item-$app--$version**
- **Ps**:
  - 1. **interface|admin|web** (using) **`bbx`|`bbz`** (as) **$item**
  - 2. **account|communal|content|project|finance|operation|marketing|mall|iam** (using) **`main`** (as) **$item**
  - 3. **im|infra|** (using) **`common`** (as) **$item**

- Example: **[build-public]bbx-interface--v1.1.0**
- Example: **[build-public]main-account--v1.1.0**
- Example: **[build-rc]common-infra--v1.1.0**
- Example: **[build-rc]bbz-admin--v1.1.0**

---

## 2. Pre-release Environment (Full Release)

**Scripts:**

- **build-all-uat.sh ---- Build Machine (1)**
- **deploy-all-uat.sh ---- Deployment Machine (2)**
- **update-app.sh ---- Pre-release Update Container**
- **update-item.sh ---- Pre-release Update Project**

**Purpose:**

- Used for full updates and releases to the pre-release environment.

**Trigger Conditions:**

### Enter the specified directory in the terminal and input **./build-all-uat.sh**

---

## 3. Production Environment (Patch Version)

**Scripts:**

- **build-prod.sh ---- Build Machine (1)**
- **deploy-prod.sh ---- Deployment Machine (2)**

**Purpose:**

- Typically used for quick updates of individual services in the production environment.

**Trigger Conditions:**

### Administrators or developers input **[buildonline-online]$item-$app--$version**
- **Ps**:
  - 1. **interface|admin|web** (using) **`bbx`|`bbz`** (as) **$item**
  - 2. **account|communal|content|project|finance|operation|marketing|mall|iam** (using) **`main`** (as) **$item**
  - 3. **im|infra|** (using) **`common`** (as) **$item**

- Example: **[buildonline-online]bbx-interface--v1.1.0**
- Example: **[buildonline-online]bbz-admin--v1.1.0**
- Example: **[buildonline-online]main-account--v1.1.0**
- Example: **[buildonline-online]common-infra--v1.1.0**

---

## 4. Production Environment (Full Release)

**Scripts:**

- **control.sh  ---- Local Deployment Personnel Machine (1)**
- **build-all-prod.sh  ---- Build Machine (2)**
- **deploy-all-prod.sh ---- Deployment Machine (3)**
- **update-item.sh ---- Official Release Update Project**

**Purpose:**

- Used for full updates and releases to the production environment.

**Trigger Conditions:**

### Enter the specified directory in the terminal and input **./control.sh**.

---

## Variables and Related Notes

- **`$build`**: Build attributes from code push.
- **`$env`**: Environment for build and deployment (e.g., public, rc, online).
- **`$item`**: Project being built (e.g., bbx, bbz).
- **`$version`**: Build version (e.g., v1.0.0).

**Attention:**
- Please submit the modified content to the code repository before each update, and attach detailed modification records (such as describing the changes through Git commit).
- After completing the code push, please go to the CHANGELOG.md file to supplement the specific details of this update, including but not limited to:
- 1. New features added
- 2. Defects repaired
- 3. Known issues or limitations
- 4. Ensure that the updated content is clear and concise, and follow the trigger requirements for building operations.
- For the construction operation of the production environment, please be sure to notify the technical leader or operations team in advance.
---
- The local build server (254) stores essential information needed for the build in **local-info.sh**, including `$build`, `$env`, `$item`, `$version`, and sensitive information (not uploaded to the code repository).
- The production environment remote server (237) stores the required build information in **local_prod_info.sh**, including `$build`, `$env`, `$item`, `$version`, and sensitive information (not uploaded to the code repository).
