#!/bin/bash
# Keepalived診断スクリプト
echo "========================================"
echo "Keepalived診断スクリプト"
echo "========================================"
echo ""
# 1. 基本情報
echo "[1] 基本情報"
echo "Hostname: $(hostname)"
echo "Date: $(date)"
echo ""
# 2. Keepalived状態
echo "[2] Keepalived状態"
systemctl is-active keepalived && echo "✓ Running" || echo "X Stopped"
echo ""
# 3. HAProxy状態
echo "[3] HAProxy状態"
systemctl is-active haproxy && echo "✓ Running" || echo "X Stopped"
echo ""
# 4. VIP確認
echo "[4] VIP確認"
VIP_COUNT=$(ip addr show | grep -c "192.168.100.10")
if [ $VIP_COUNT -gt 0 ]; then
    echo "✓ VIP is assigned (MASTER)"
    ip addr show | grep "192.168.100.10"
else
    echo "○ VIP not assigned (BACKUP)"
fi
echo ""
# 5. VRRP通信確認
echo "[5] VRRP通信確認(5秒間)"
timeout 5 tcpdump -i ens18 proto 112 -c 5 2>&1 | grep -E "vrid|captured"
echo ""
# 6. ファイアウォール確認
echo "[6] ファイアウォール確認"
if command -v ufw &> /dev/null; then
    ufw status | grep -E "Status|vrrp|112" || echo "UFW not configured for VRRP"
fi
iptables -L INPUT -n | grep -q "112" && echo "✓ iptables allows VRRP" || echo "○ iptables rule not found"
echo ""
# 7. カーネルパラメータ確認
echo "[7] カーネルパラメータ確認"
echo "ip_nonlocal_bind: $(sysctl -n net.ipv4.ip_nonlocal_bind)"
echo "ip_forward: $(sysctl -n net.ipv4.ip_forward)"
echo ""
# 8. 最新ログ
echo "[8] 最新ログ(最近10行)"
journalctl -u keepalived -n 10 --no-pager
echo ""
# 9. ヘルスチェック動作確認
echo "[9] ヘルスチェック動作確認"
if /usr/bin/killall -0 haproxy 2>/dev/null; then
    echo "✓ HAProxy health check: PASS"
else
    echo "X HAProxy health check: FAIL"
fi
echo ""
echo "========================================"
echo "診断完了"
echo "========================================"
