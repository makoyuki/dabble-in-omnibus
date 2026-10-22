#!/bin/bash
# rspamd のログを監視して、reject したメールがあれば管理者にメールで知らせる

LOGFILE="/var/log/rspamd/rspamd.log"
# 通知に載せるシンボル(この節で設定したもの)
PATTERN="\b(BAD_ATTACHMENT|REGEXP_JS_IN_BODY|REGEXP_VBS_IN_BODY|REGEXP_ACTIVEX_IN_BODY)\b"
# 判定結果が reject のもの
REJECT_ACTION_PATTERN="\(default: T \(reject\): \[[0-9.]+/[0-9.]+\]"
EMAIL="adm@example.jp"
HOSTNAME=$(hostname)

# デバッグログファイルのパス
DEBUGLOG="/var/log/rspamd/monitor_debug.log"
echo "Starting log monitoring..." > "$DEBUGLOG"

tail -F "$LOGFILE" | while read -r line; do
  # 1通ごとの判定結果の行(rspamd_task_write_log)のうち、reject したものだけを通知する
  if [[ "$line" =~ "rspamd_task_write_log" ]] && [[ "$line" =~ $REJECT_ACTION_PATTERN ]]; then
    SYMBOLS=$(echo "$line" | grep -oP "$PATTERN" | sort -u | paste -sd, -)
    [[ -z "$SYMBOLS" ]] && SYMBOLS="Other Reason"
    FROM=$(echo "$line" | grep -oP '(?<=from: <)[^>]+')
    TO=$(echo "$line" | grep -oP '(?<=, rcpts: <)[^>]+')
    IP=$(echo "$line" | grep -oP '(?<=ip: )[0-9.]+')
    ID=$(echo "$line" | grep -oP '(?<=id: <)[^>]+')
    printf "%s を検出したためブロックしました。\n-----------------------\nサーバ名: %s\n送信者: %s\n受信者: %s\nIP: %s\nメッセージID: %s\n-----------------------\nログ: %s\n" \
      "$SYMBOLS" "$HOSTNAME" "$FROM" "$TO" "$IP" "$ID" "$line" | mail -s "ADMIN_Default_Block[$SYMBOLS]" "$EMAIL"
    echo "SYMBOLS=$SYMBOLS, FROM=$FROM, TO=$TO" >> "$DEBUGLOG"
  fi
done
