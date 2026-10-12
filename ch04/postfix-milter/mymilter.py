import Milter
import os
import sys
from email.utils import parseaddr

# 特定のメールアドレスのセット
SPECIAL_EMAIL_ADDRESSES = {
    'user1@example.com',
    'user2@example.com',
    'user3@example.com',
}

class MyMilter(Milter.Base):
    def __init__(self):
        self.id = Milter.uniqueID()
        self.add_special_header = False

    def header(self, header_field, header_value):
        # From, To, Ccヘッダをチェックし、特定のメールアドレスが含まれているか確認
        if header_field.lower() in ("from", "to", "cc"):
            addresses = header_value.split(',')
            for address in addresses:
                # Parse the email address from the header
                email_address = parseaddr(address)[1].lower()
                if email_address in SPECIAL_EMAIL_ADDRESSES:
                    self.add_special_header = True
                    break
        return Milter.CONTINUE

    def eom(self):
        # メール終端（end-of-message）時に特別なヘッダーを追加
        if self.add_special_header:
            self.addheader('X-Special-Header', 'MyHeaderValue')
            self.add_special_header = False  # Reset for the next message
        return Milter.ACCEPT

def main():
    port = 30025  # 待ち受けるポートを指定
    timeout = 600  # タイムアウト設定（秒）

    # Milterクラスとソケットオプションを設定
    Milter.factory = MyMilter
    Milter.set_flags(Milter.ADDHDRS | Milter.CHGBODY | Milter.CHGHDRS)
    sys.stdout.flush()

    # Milterサーバーを開始 (ローカルホストの指定ポートで待ち受け)
    Milter.runmilter("mymilter", "inet:%d@localhost" % port, timeout)

# スクリプトの実行ポイント
if __name__ == "__main__":
    main()
