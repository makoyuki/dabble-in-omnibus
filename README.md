# Dabble in... 総集編 Vol.1–14 収録コード

技術同人誌「Dabble in... 総集編 Vol.1–14」(Far Northern Other World)に収録した記事のうち、長いスクリプトや設定ファイルを章ごとに置いているリポジトリです。本書では、これらのファイルは全文を載せずに、このリポジトリを案内しています。

- 内容は各号の執筆当時のものです。OSやソフトウェアのバージョンが変わっているものも多いので、そのまま実環境に使わず、手元の環境に合わせて確認してください。
- ホスト名・ドメイン名・IPアドレスなどは、`example.jp` や `192.168.x.x` などに置き換えています。

## 構成

| フォルダ | 内容 | 初出 |
|---|---|---|
| `ch02/dnsmasq/` | ローカルDNS(dnsmasq)の設定 | Vol.2 |
| `ch02/phpldapadmin/` | phpLDAPadminを改造したパスワード変更・リセット(設定とCGI) | Vol.2 |
| `ch02/openmeetings/` | Apache OpenMeetingsの起動スクリプト(init.d) | Vol.2 |
| `ch04/postfix-milter/` | Postfixのmilter(Python) | Vol.6 |
| `ch04/pop3proxy/` | POP3 Proxy(Python) | Vol.7 |
| `ch04/pop3proxy-v2/` | POP3 Proxyの構成見直し版(dovecotと組み合わせる版。総集編で修正あり) | Vol.7 補足版 |
| `ch04/rspamd/` | rspamdでヘッダを追加するLuaスクリプト | Vol.8 |
| `ch04/messasy/` | Messasyの設定 | Vol.11 |
| `ch05/ldap-password-ui/` | LDAPパスワード変更用Web UI(PHP) | Vol.7 |
| `ch05/nis2ldap/` | NIS→LDAPのアカウント移行スクリプト(sh・awk) | Vol.8 |
| `ch05/autofs/` | autofsのマップをLDAPに登録するLDIF | Vol.8 |
| `ch05/haproxy/`, `ch05/keepalived/` | HAProxyによるLDAP用LBと、keepalivedの通知・診断スクリプト | Vol.12 |
| `ch06/openvpn/` | OpenVPNのLDAP認証用スクリプト(Python) | Vol.6 |

## 総集編での修正

- `ch04/pop3proxy-v2/pop3proxy.py`
  - 1行で応答が返るコマンド(USER・PASSなど)と、複数行で返るコマンド(RETR・TOP、引数なしのLIST・UIDLなど)を分けて受け取るようにした
  - スパムと判定したときに、SpamAssassinがヘッダを追加したメールに正しく差し替えるようにした(以前は判定もできていなかった)
  - ログにパスワード(PASSコマンド)を書かないようにし、メール本文まるごとのログはDEBUGのときだけにした
  - 元の原稿でコメントの `#` が抜けていた行を直した
- `ch06/openvpn/ldap_auth.py`、`ch05/autofs/automount.ldif`: 本文向けに付けていた注釈を、それぞれPython・LDIFのコメントに直した
- `ch05/nis2ldap/scripts/`: 当時配布していたアーカイブのまま。改行をLFに、文字コードをUTF-8にそろえた

## 別のリポジトリにあるもの

- 第6章 NetFlow(ng_netflow): https://github.com/makoyuki/FreeBSD-Netflow-Export
- 第7章 動画の英語音声の翻訳・字幕付与: https://github.com/makoyuki/video_translator
- 第8章 抽選用スクリプト: https://github.com/makoyuki/prise_lottery
- 第8章 Felicaを利用した出退勤記録システム: https://github.com/makoyuki/attendance_system

## ライセンス

MIT License(`LICENSE` を参照)
