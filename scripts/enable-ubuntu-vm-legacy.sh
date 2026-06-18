#!/usr/bin/env bash
set -euo pipefail

USER_SERVICE_ID="${1:-}"
DURATION="${DURATION:-120}"

if [[ "$(id -u)" -ne 0 ]]; then
  echo "请用 root 执行：sudo bash scripts/enable-ubuntu-vm-legacy.sh <userServiceId>" >&2
  exit 1
fi

if [[ -z "$USER_SERVICE_ID" ]]; then
  echo "用法：sudo bash scripts/enable-ubuntu-vm-legacy.sh <userServiceId>" >&2
  exit 1
fi

if [[ ! -x /usr/local/bin/yidongyun ]]; then
  echo "缺少 /usr/local/bin/yidongyun，请先执行：sudo bash scripts/install.sh" >&2
  exit 1
fi

mkdir -p /etc/yidongyun /var/log/yidongyun
chmod 700 /etc/yidongyun

cat >/etc/yidongyun/yidongyun.env <<EOF
YDY_HOME=/etc/yidongyun
YDY_CLIENT_ROOT=/opt/yidongyun/client/opt/chuanyun-vdi-client
USER_SERVICE_ID=$USER_SERVICE_ID
DURATION=$DURATION
QT_QPA_PLATFORM=offscreen
YDY_LEGACY_DISCONNECT=1
EOF
chmod 600 /etc/yidongyun/yidongyun.env

cat >/usr/local/bin/yidongyun-keepalive-legacy.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

LOCK=/tmp/yidongyun-keepalive-legacy.lock
LOG_DIR=/var/log/yidongyun
LOG_FILE="$LOG_DIR/keepalive-legacy.log"
ENV_FILE=/etc/yidongyun/yidongyun.env

mkdir -p "$LOG_DIR"

if [[ -f "$LOG_FILE" ]] && [[ "$(stat -c%s "$LOG_FILE")" -gt 5242880 ]]; then
  tail -c 1048576 "$LOG_FILE" > "$LOG_FILE.tmp"
  mv "$LOG_FILE.tmp" "$LOG_FILE"
fi

exec 9>"$LOCK"
if ! flock -n 9; then
  exit 0
fi

set -a
. "$ENV_FILE"
set +a

exec >>"$LOG_FILE" 2>&1

echo "===== $(date '+%F %T') keepalive start ====="
/usr/local/bin/yidongyun keepalive --user-service-id "$USER_SERVICE_ID" --duration "$DURATION"
echo "===== $(date '+%F %T') keepalive end ====="
EOF
chmod 0755 /usr/local/bin/yidongyun-keepalive-legacy.sh

cat >/etc/cron.d/yidongyun-keepalive-legacy <<'EOF'
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

*/10 * * * * root /usr/local/bin/yidongyun-keepalive-legacy.sh
EOF
chmod 0644 /etc/cron.d/yidongyun-keepalive-legacy

systemctl disable --now yidongyun-keepalive.timer >/dev/null 2>&1 || true

echo "Ubuntu VM legacy 保活已启用。"
echo "手动测试：sudo /usr/local/bin/yidongyun-keepalive-legacy.sh"
echo "查看日志：tail -n 100 /var/log/yidongyun/keepalive-legacy.log"
