#!/bin/bash
# Keepalived状態変更通知スクリプト

TYPE=$1
NAME=$2
NOW=$(date '+%Y-%m-%d %H:%M:%S')
HOSTNAME=$(hostname)
ALERT_EMAIL="adm@example.jp"

# ログ出力
echo "$NOW - $HOSTNAME transitioned to $TYPE state for $NAME" >> /var/log/keepalived-notify.log

case $TYPE in
    MASTER)
        MESSAGE="$HOSTNAME became MASTER for $NAME at $NOW"
        SUBJECT="[HAProxy] $HOSTNAME is now MASTER"
        logger -t keepalived "$MESSAGE"

        # メール送信
        echo "$MESSAGE" | mail -s "$SUBJECT" "$ALERT_EMAIL"
        ;;

    BACKUP)
        MESSAGE="$HOSTNAME became BACKUP for $NAME at $NOW"
        SUBJECT="[HAProxy] $HOSTNAME is now BACKUP"
        logger -t keepalived "$MESSAGE"

        # メール送信
        echo "$MESSAGE" | mail -s "$SUBJECT" "$ALERT_EMAIL"
        ;;

    FAULT)
        MESSAGE="$HOSTNAME detected FAULT for $NAME at $NOW"
        SUBJECT="[CRITICAL] HAProxy FAULT on $HOSTNAME"
        logger -t keepalived -p user.crit "$MESSAGE"

        # メール送信
        echo "$MESSAGE" | mail -s "$SUBJECT" "$ALERT_EMAIL"
        ;;
esac

exit 0
