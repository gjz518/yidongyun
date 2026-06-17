# yidongyun

移动云电脑 Linux 辅助连接工具。它在服务器环境中调用官方 Linux 客户端组件完成定时连接检查，并通过 systemd timer 周期运行。

本仓库不包含官方客户端安装包、解包后的 SDK、登录 token 或手机号。安装脚本会从移动云电脑官方地址下载客户端包并在本机解包。

## 环境要求

- Linux x86_64
- root 权限
- Node.js 18 或更新版本
- systemd
- 能访问 `https://soho.komect.com`

### Ubuntu Server

Ubuntu Server 可以直接使用本仓库的 systemd timer 部署方式，不需要使用旧的 cron 脚本。

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

### 飞牛 NAS / Debian 系统

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

## 部署

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

把实际的 `userServiceId` 写入 systemd 定时器配置：

```bash
sudo bash scripts/install-systemd.sh <userServiceId>
```

## 常用命令

手动运行一次连接检查：

```bash
sudo yidongyun keepalive --user-service-id <userServiceId> --duration 120
```

查看定时器：

```bash
systemctl list-timers yidongyun-keepalive.timer
```

查看最近日志：

```bash
journalctl -u yidongyun-keepalive.service -n 100 --no-pager
```

重新登录：

```bash
sudo yidongyun sms-send <手机号>
sudo yidongyun sms-login <手机号> <短信验证码>
```

## 文件位置

- 命令：`/usr/local/bin/yidongyun`
- 登录状态：`/etc/yidongyun/state.json`
- systemd 配置：`/etc/yidongyun/yidongyun.env`
- 官方客户端解包目录：`/opt/yidongyun/client`

`/etc/yidongyun/state.json` 包含登录 token，权限应保持为 `600`，不要提交到 GitHub。

## 排查

如果提示缺少 SDK，重新执行：

```bash
sudo bash scripts/install.sh
```

如果接口返回登录失效，重新执行短信登录。若定时任务没有按时运行，先看 timer 和 service 日志：

```bash
systemctl status yidongyun-keepalive.timer --no-pager
journalctl -u yidongyun-keepalive.service -n 100 --no-pager
```
