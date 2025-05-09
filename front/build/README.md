<p style="text-align: center;">
    <a href="https://biaobiaoxing.com">
        <img src="https://static.dingtalk.com/media/lAHPDfJ6fbPRTQTNASzNASw_300_300.gif?bizType=im" width="40%"  alt=""/>
    </a>
</p>

# **Overview of Frontend  Website CI/CD Script Directory**

_This document describes the CI/CD scripts for different environments._
\[ [中文](README.zh-CN.md) | English \]

### Directory Structure
```
├── build # CI/CD script directory
│     ├── beta # Testing environment
│     │     └── deploy-deploy.sh # Public testing pre-release environment build deployment script
│     ├── prod
│     │     ├── build-prod.sh    # Production environment build script
│     │     └── deploy-prod.sh   # Production environment deployment script
│     ├── README.md
│     └── README.zh-CN.md
├── CHANGELOG.md                
```

## 1. Public Testing | Pre-release Environment

**Script:**

- **build-deploy.sh ---- Simplified CI/CD process for public testing and pre-release environments on local servers**

**Purpose:**

- For developers to quickly deploy to public testing and pre-release environments.

**Trigger Condition:**

### Developers input **[build-$env]$version**
- **Ps**:
- Example: **[build-public]v1.1.0**
- Image name: public-galaxy-pc-nuxt3:v1.1.0
- Example: **[build-rc]v1.1.0**
- Image name: rc-galaxy-pc-nuxt3:v1.1.0

---
## 2. Production Environment

**Script:**

- **build-prod.sh ---- Build machine (1)**
- **deploy-prod.sh ---- Deployment release machine (2)**

**Purpose:**

- For quick updates to the official website in the production environment.

**Trigger Condition:**

### Administrator or developer inputs **[buildonline-online]$version**
- **Ps**:
- Example: **[buildonline-online]v1.1.0**
- Image name: online-galaxy-pc-nuxt3:v1.1.0

---

## Variables and Related Explanations

- **`$build`**: Build attribute of the code push.
- **`$version`**: Build version (e.g., v1.1.0).

**Attention:**
- Please submit the modified content to the code repository before each update, and attach detailed modification records (such as describing the changes through Git commit).
- After completing the code push, please go to the  [CHANGELOG.md](../CHANGELOG.md) file to supplement the specific details of this update, including but not limited to:
- 1. New features added
- 2. Defects repaired
- 3. Known issues or limitations
- 4. Ensure that the updated content is clear and concise, and follow the trigger requirements for building operations.
- For the construction operation of the production environment, please be sure to notify the technical leader or operations team in advance.
---
- The local build server (254) stores the basic information required for building, including `$build`, `$env`, `$version`, and sensitive information (which is not uploaded to the code repository with the project), in the working directory of **node-local-info.sh**
- The remote server (237) in the production environment stores the basic information required for building, including `build`, `env`, `version`, and sensitive information (which is not uploaded to the code repository with the project), in the working directory of **node-local-info.sh**



