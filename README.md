# yidongyun

移动云电脑协议级保活工具。它复用官方 Linux 客户端里的中兴云电脑 SDK，在无图形界面的服务器上以 `offscreen` 模式完成连接和 Display Surface 创建，用 systemd timer 每 10 分钟保活一次。

本仓库不包含官方客户端安装包、解包后的 SDK、登录 token 或手机号。安装脚本会从移动云电脑官方地址下载客户端包并在本机解包。

## 环境要求

- Linux x86_64
- root 权限
- Node.js 18 或更新版本
- systemd
- 能访问 `https://soho.komect.com`

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

把实际的 `userServiceId` 写入 systemd 定时器：

```bash
sudo bash scripts/install-systemd.sh <userServiceId>
```

## 常用命令

手动保活 120 秒：

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

如果接口返回登录失效，重新执行短信登录。若保活没有按时运行，先看 timer 和 service 日志：

```bash
systemctl status yidongyun-keepalive.timer --no-pager
journalctl -u yidongyun-keepalive.service -n 100 --no-pager
```
