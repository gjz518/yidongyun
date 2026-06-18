# yidongyun

移动云电脑 Linux 辅助连接工具。它在服务器环境中调用官方 Linux 客户端组件完成定时连接检查。

本仓库不包含官方客户端安装包、解包后的 SDK、登录 token 或手机号。安装脚本会从移动云电脑官方地址下载客户端包并在本机解包。

## 环境要求

- Linux x86_64
- root 权限
- Node.js 18 或更新版本
- systemd
- 能访问 `https://soho.komect.com`

### Ubuntu VM legacy 模式（推荐）

推荐在飞牛 NAS 里创建一个 Ubuntu x86_64 虚拟机，然后在虚拟机里运行 legacy cron 保活。

这个模式用于复现已验证稳定的旧服务器行为：

- 每 10 分钟运行一次
- 每次保持 120 秒
- 使用 legacy disconnect 逻辑
- 使用 cron 调度
- 日志写入 `/var/log/yidongyun/keepalive-legacy.log`

部署前建议确认：

```bash
uname -m
cat /etc/os-release
command -v apt
command -v systemctl
node -v
```

推荐条件：

- `uname -m` 为 `x86_64`
- Ubuntu 20.04 或更新版本
- 系统可使用 `apt`
- Node.js 为 18 或更新版本
- 可使用 `systemctl`

如果旧服务器上已经配置过其他保活脚本，建议先停掉旧定时任务，避免多台设备或多个脚本同时连接同一台云电脑。

### 飞牛 NAS / Debian 宿主系统（实验）

可以在飞牛 NAS / Debian 宿主系统上安装依赖和运行客户端，但这个模式不作为推荐保活方案。

飞牛 NAS 上建议先确认环境：

```bash
uname -m
cat /etc/os-release
command -v apt
command -v systemctl
node -v
```

推荐条件：

- `uname -m` 为 `x86_64`
- 系统可使用 `apt`
- Node.js 为 18 或更新版本
- 可使用 `systemctl`

如果是 ARM 架构，官方 Linux 客户端包不可用，本工具无法直接部署。若系统自带 Node.js 低于 18，请先升级 Node.js 后再运行安装脚本。

实测中，FnOS / Debian 宿主系统可以完成 `connectDesktop ret val: 0`，但不一定能阻止移动云电脑空闲关机。需要稳定保活时，优先使用 Ubuntu VM legacy 模式。

## Ubuntu VM 部署

```bash
git clone git@github.com:gjz518/yidongyun.git
cd yidongyun
sudo bash scripts/install.sh
```

安装完成后登录：

```bash
sudo yidongyun sms-send <手机号>
sudo yidongyun sms-login <手机号> <短信验证码>
sudo yidongyun list
```

`list` 会输出云电脑列表，例如：

```text
0: userServiceId=1234567 vmName=青藤 spuCode=zte-cloud-pc
```

把实际的 `userServiceId` 写入 legacy cron 配置：

```bash
sudo bash scripts/enable-ubuntu-vm-legacy.sh <userServiceId>
```

手动运行一次：

```bash
sudo /usr/local/bin/yidongyun-keepalive-legacy.sh
```

查看 legacy 日志：

```bash
tail -n 100 /var/log/yidongyun/keepalive-legacy.log
```

确认 cron 已安装：

```bash
cat /etc/cron.d/yidongyun-keepalive-legacy
```

## 常用命令

手动运行一次连接检查：

```bash
sudo yidongyun keepalive --user-service-id <userServiceId> --duration 120
```

查看 legacy cron：

```bash
cat /etc/cron.d/yidongyun-keepalive-legacy
```

查看最近 legacy 日志：

```bash
tail -n 100 /var/log/yidongyun/keepalive-legacy.log
```

重新登录：

```bash
sudo yidongyun sms-send <手机号>
sudo yidongyun sms-login <手机号> <短信验证码>
```

## 文件位置

- 命令：`/usr/local/bin/yidongyun`
- legacy 保活脚本：`/usr/local/bin/yidongyun-keepalive-legacy.sh`
- legacy cron：`/etc/cron.d/yidongyun-keepalive-legacy`
- 登录状态：`/etc/yidongyun/state.json`
- 配置：`/etc/yidongyun/yidongyun.env`
- legacy 日志：`/var/log/yidongyun/keepalive-legacy.log`
- 官方客户端解包目录：`/opt/yidongyun/client`

`/etc/yidongyun/state.json` 包含登录 token，权限应保持为 `600`，不要提交到 GitHub。

## 重装恢复

飞牛 NAS 重装或 Ubuntu VM 重建后，推荐恢复流程：

```bash
git clone git@github.com:gjz518/yidongyun.git
cd yidongyun
sudo bash scripts/install.sh
sudo yidongyun sms-send <手机号>
sudo yidongyun sms-login <手机号> <短信验证码>
sudo yidongyun list
sudo bash scripts/enable-ubuntu-vm-legacy.sh <userServiceId>
sudo /usr/local/bin/yidongyun-keepalive-legacy.sh
```

如果有本地安全备份，也可以恢复：

```text
/etc/yidongyun/state.json
/etc/yidongyun/yidongyun.env
```

不要把这些文件提交到 GitHub。

## 排查

如果提示缺少 SDK，重新执行：

```bash
sudo bash scripts/install.sh
```

如果接口返回登录失效，重新执行短信登录。若定时任务没有按时运行，先看 cron 和 legacy 日志：

```bash
cat /etc/cron.d/yidongyun-keepalive-legacy
tail -n 100 /var/log/yidongyun/keepalive-legacy.log
```
