# Launchpad：前端 CI/CD 学习 Demo

无 npm、无前端框架、无第三方 CDN。HTML/CSS/JS → Nginx 镜像 → 单节点 K3s。
页面的流程图是教学示意，版本、commit、构建时间来自当前镜像，不代表实时集群监控。

## 1. 前提与首次手工部署

在现有 Linux 虚拟机上运行。需要 Git、Docker、curl、bash、K3s，且节点 Ready。
先把本目录内容提交到你自己的 Git 仓库，再在虚拟机克隆、进入仓库目录。
不要将 Jenkins 密码、GitHub Token、kubeconfig 提交到 Git。

执行账户需要 Docker 权限，并可用 `sudo -n k3s`。root 手工实验也需确保 sudo 可用。
Jenkins Agent 尚未配置；此项目不会自动创建 Agent 或修改 sudoers。
Docker 权限与 K3s 管理权限都很高，Agent 应使用专用账户，后续配置时明确授权范围。

```bash
git clone <你的真实仓库地址> cicd-demo
cd cicd-demo
bash scripts/deploy.sh manual-001
```

基础镜像 `nginx:stable-alpine` 首次构建需要 Docker 能下载。之后可固定已验证的 digest。
镜像只导入当前单节点；不适用于未经调整的多节点集群。
部署清单是模板，必须通过脚本替换 `__IMAGE__`，不要直接 apply 原文件。

浏览器访问 http://192.168.200.100:30081 。如防火墙拦截，仅在本地可信网络开放 TCP 30081。
Headlamp 选择 demo 命名空间，查看 Deployment、两个 Pod、Service 与事件。

## 2. Jenkins 接入

1. 配置位于这台 K3s 虚拟机的 Linux Agent，标签设为 `linux-k3s`；Java 版本需按实际 Jenkins 版本核验。
2. 确认 Agent 账户可运行 Git、Docker、curl、bash，以及脚本里的 `sudo -n k3s`。
3. Jenkins 新建 Pipeline，选择 **Pipeline script from SCM → Git**。
4. 填真实仓库 URL、实际分支（如 `*/main`），脚本路径填 `Jenkinsfile`。
5. 私有仓库认证放 Jenkins Credentials，不写入文件。公开仓库可匿名读取。
6. 第一次点击“立即构建”。成功后流水线每约 2 分钟检查提交变化，有变化自动构建。

轮询由 Jenkins 主动访问 GitHub，适合当前 localhost Jenkins。GitHub Webhook 无法直接访问
你电脑的 127.0.0.1；目前不需要将 Jenkins 暴露公网。

## 3. 验证第二次发布

修改 `site/release.js`，将 `v1.0.0` 改为 `v1.1.0`，并更改 message。

```bash
git add site/release.js
git commit -m "Update demo release to v1.1.0"
git push
```

等待 Jenkins 自动构建成功，再刷新网页。应看到新文案、新版本、对应 commit 和新的构建编号。
流水线会等待 rollout，并请求 NodePort 的 build.json 核对 commit/构建编号；不匹配会失败。
不要同时手工部署与运行 Jenkins 发布，否则可能相互覆盖。

## 4. 自愈与回滚（Linux CLI）

```bash
sudo k3s kubectl get pods -n demo
# 选一个业务 Pod 名称替换下方占位符，观察 Deployment 自动补充副本
sudo k3s kubectl delete pod <业务Pod名称> -n demo
sudo k3s kubectl get pods -n demo -w
# Ctrl+C 结束观察
sudo k3s kubectl rollout history deployment/cicd-demo -n demo
sudo k3s kubectl rollout undo deployment/cicd-demo -n demo
sudo k3s kubectl rollout status deployment/cicd-demo -n demo --timeout=180s
```

旧镜像必须仍保留在 containerd 中。回滚不会回退 Git；下一次自动发布仍以 Git 内容为准。
不要给 Headlamp 查看账户提升管理员权限来执行这些操作。

## 验收

- Git push 后自动触发 Jenkins，构建与 rollout 成功。
- 浏览器版本、文案、commit 与本次提交一致。
- 删除 Pod 后自动恢复两个就绪副本。
- 回滚后恢复旧页面，流水线失败可从阶段日志定位。

完成这些步骤，即跑通本地单节点 CI/CD 的基础闭环；镜像仓库、多节点、生产审批等可后续学习。
