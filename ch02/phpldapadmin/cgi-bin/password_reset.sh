#!/bin/sh
# "パスワードリセット"
#####################################################################
# 応答画面描画ルーチン
#
# $1: TITLE
# $2: BODY
#
function renderHTML () {
        echo "Content-Type: text/html"
        echo ""
        echo "<!doctype html>"
        echo "<html>"
        echo "<head>"
        echo "<meta http-equiv=\"Content-type\" content=\"text/html; charset=UTF-8\" />"
        echo "<title>$1</title>"
        echo "</head>"
        echo "<body>$2</body>"
        echo "</html>"
}
#####################################################################
# POST されたメールアドレスの抽出
# mail=... の形式で標準入力に渡ってくる
#
read POST
MAIL_ADDRESS=`echo $POST | awk -F= '{print $2}' | sed -e 's/%40/@/g'`
# パーセントエンコーディングによって @ が %40 で渡ってくるので、@ に置換
# メールアドレス形式のチェック
#
# ----- test.com 自明
echo $MAIL_ADDRESS | grep "^[A-Za-z0-9_\.\-]\{1,\}@test.com$" > /dev/null 2>&1> /dev/null 2>&1
if [ $? -ne 0 ]; then
        TITLE="not_mail-address-format"
        BODY="$MAIL_ADDRESSはメールアドレス形式ではないようです。"
        renderHTML $TITLE $BODY
        exit 1
fi
#####################################################################
# LDAP 登録されているメールアドレスかどうかのチェック
#
SEARCH_PATTERN="(mail=${MAIL_ADDRESS})"
# anonymous 接続
SEARCH_RET=`/usr/bin/ldapsearch -x -b "cn=members,ou=People,dc=test,dc=com" ${SEARCH_PATTERN}`
if [ `echo $SEARCH_RET | grep givenName | wc -l` -eq 0 ]; then
        TITLE="no_mail-address_entry"
        BODY="$MAIL_ADDRESSはLDAP(test.com)に未登録のアドレスです。"
        renderHTML $TITLE $BODY
        exit 1
fi
DBODY="$DBODY<br>SEARCH_PATTERN=$SEARCH_PATTERN<br>SEARCH_RET=$SEARCH_RET"
#renderHTML "debug" "$DBODY"
#exit 1
#####################################################################
# ランダムパスワード文字列とそのハッシュ値を生成
#
USER_ID_DATA=`/usr/bin/ldapsearch -x -b "cn=members,ou=People,dc=test,dc=com" ${SEARCH_PATTERN} | grep ^dn`
PLAIN_PW=`/sbin/slappasswd -g`
HASHED_PW=`echo -n $PLAIN_PW | slappasswd -T /dev/stdin`
DBODY="$DBODY<br>PLAIN_PW=$PLAIN_PW<br>HASHED_PW=$HASHED_PW"
#renderHTML "debug" "$DBODY"
#exit 1
#####################################################################
# ldapmodify で更新
#
# ----- 1. LDIF 作成
LDIF=/tmp/ldif.`date +%Y%m%d%H%M`
cat << EOL1 > $LDIF
${USER_ID_DATA}
changetype: modify
replace: userPassword
userPassword: ${HASHED_PW}
EOL1
DBODY="$DBODY<br>LDIF=$LDIF"
#renderHTML "debug" "$DBODY"
#exit 1
# ----- 2. パスワードハッシュ値を更新
MODIFY_RET=`/usr/bin/ldapmodify -x -D "cn=Manager,dc=test,dc=com" -w password -f $LDIF`
if [ `echo $MODIFY_RET | grep "modifying entry" | wc -l` -ne 1 ]; then
        TITLE="failed_replacing_password-hashed_value"
        BODY="パスワードハッシュ値の更新に失敗しました。"
        renderHTML $TITLE $BODY
        exit 1
fi
# ----- 3. LDIF を削除
rm -f $LDIF
DBODY="$DBODY<br>MODIFY_RET=$MODIFY_RET"
#renderHTML "debug" "$DBODY"
#exit 1
#####################################################################
# メールで通知
#
(env LC_ALL=ja_JP.UTF8 mail -s "password reset (test.com)" $MAIL_ADDRESS) << EOL2
LDAP(test.com)のあなたのパスワードを
次の値にリセットしました。
    $PLAIN_PW
適宜変更してご利用ください。
EOL2
if [ $? -ne 0 ]; then
        TITLE="failed_mail-sending"
        BODY="メール送信に失敗しました。"
        renderHTML $TITLE $BODY
        exit 1
fi
#renderHTML "debug" "$DBODY"
#exit 1
renderHTML "password reset (test.com)" "リセットしたパスワードをメールでお送りしました。"
