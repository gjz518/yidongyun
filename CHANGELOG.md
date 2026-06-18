# Changelog

## 2026-06-18

### Ubuntu VM legacy 可复制部署

本次更新把已验证稳定的 Ubuntu 虚拟机保活方式整理为可复制部署流程。

#### 新增

- 新增 `YDY_LEGACY_DISCONNECT=1`，用于启用 legacy disconnect 行为。
- 新增 `scripts/enable-ubuntu-vm-legacy.sh`：
  - 写入 `/etc/yidongyun/yidongyun.env`
  - 安装 `/usr/local/bin/yidongyun-keepalive-legacy.sh`
  - 安装 `/etc/cron.d/yidongyun-keepalive-legacy`
  - 每 10 分钟运行一次，每次保持 120 秒
- README 增加 Ubuntu VM legacy 推荐部署流程和重装恢复说明。

#### 调整

- 将飞牛 NAS / Debian 宿主系统标记为实验模式。
- 文档明确：FnOS / Debian 宿主系统可以连接成功，但不一定能阻止移动云电脑空闲关机。
- 稳定保活推荐在飞牛 NAS 内的 Ubuntu x86_64 虚拟机中运行 legacy cron。

## 2026-06-17

### 飞牛 NAS / Debian 12 兼容性更新

本次更新主要针对在飞牛 NAS 上部署和运行时发现的问题做兼容处理。

#### 新增

- README 增加飞牛 NAS / Debian 系统部署前检查说明。
- 安装脚本支持 Debian 12 和 Ubuntu 24.04 的不同 Qt 依赖包名。
- 安装脚本增加 Node.js 版本检查，要求 Node.js 18 或更新版本。

#### 修复

- 修复 Debian 12 上缺少 `libpulse-mainloop-glib.so.0` 导致官方客户端启动失败的问题。
  - 新增依赖：`libpulse-mainloop-glib0`
- 修复断开连接时使用占位参数导致 SDK 日志出现断连警告的问题。
  - `disconnect` 现在复用真实连接参数。

#### 已验证环境

```text
系统：Debian GNU/Linux 12 bookworm
设备：飞牛 NAS
架构：x86_64
Node.js：v22.22.3
systemd：可用
apt：可用
```

#### 验证结果

```text
安装：成功
短信登录：成功
云电脑列表：成功
systemd timer：启用成功
keepalive service：运行完成，退出码 0/SUCCESS
```

#### 注意事项

- ARM / aarch64 设备仍无法直接运行，因为官方 Linux 客户端包是 x86 架构。
- 首次安装会下载官方客户端包，体积约 235 MB。
- 解包后 `/opt/yidongyun` 约占用 1.4 GB。
- 同一个云电脑不建议在多台设备上同时运行定时连接任务。
