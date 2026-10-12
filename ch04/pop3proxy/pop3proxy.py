import socket
import threading
import subprocess
import logging
from concurrent.futures import ThreadPoolExecutor
import pyclamd

LOCAL_HOST = '0.0.0.0'
LOCAL_PORT = 9110  # 特権不要なポートを使用
REMOTE_HOST = '【メールサーバのアドレス】'
REMOTE_PORT = 110
MAX_THREADS = 100  # 最大スレッド数を設定
TIMEOUT = 60  # 秒

# ログ設定
logging.basicConfig(
    filename='/var/log/pop3proxy.log',
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

def scan_spam(message):
    try:
        proc = subprocess.Popen(['spamc'], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        stdout, stderr = proc.communicate(input=message, timeout=TIMEOUT)
        if stderr:
            logging.error(f"SpamAssassin Error: {stderr}")
        return b'X-Spam-Flag: YES' in stdout, stdout
    except subprocess.TimeoutExpired:
        logging.error("SpamAssassin process timed out")
        proc.kill()
        return False, message

def handle_client(client_socket):
    try:
        remote_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        remote_socket.settimeout(TIMEOUT)  # タイムアウト設定
        remote_socket.connect((REMOTE_HOST, REMOTE_PORT))

        cd = pyclamd.ClamdNetworkSocket(host='127.0.0.1', port=3310)

        while True:
            client_data = client_socket.recv(4096)
            if not client_data:
                break

            # ログに認証情報の記録 (例：実際の運用では削除)
            if client_data.startswith(b'USER') or client_data.startswith(b'PASS'):
                logging.info(f'Client data: {client_data.strip()}')

            # クライアントからのデータをリモート（メールサーバ）に送信
            remote_socket.sendall(client_data)

            # リモート（メールサーバ）からのデータを受信
            response_data = remote_socket.recv(4096)

            if client_data.startswith(b'RETR'):
                message = b''
                while True:
                    part = remote_socket.recv(4096)
                    message += part
                    if b'\r\n.\r\n' in part:
                        break

                # ClamAVスキャン
                clamav_result = cd.scan_stream(message)
                if clamav_result:
                    logging.warning(f'Virus detected in message: {clamav_result}')
                    client_socket.send(b'-ERR ClamAV detected a virus in the message\r\n')
                    continue

                # SpamAssassinスキャン
                is_spam, processed_message = scan_spam(message)
                if is_spam:
                    logging.info(f'Spam detected in message')
                    client_socket.send(b'-ERR Message flagged as spam\r\n')
                    continue

                client_socket.send(b'+OK\r\n')
                client_socket.sendall(processed_message)
            else:
                client_socket.sendall(response_data)
    except socket.timeout:
        logging.error("Connection to remote server timed out")
    except Exception as e:
        logging.error(f'Error handling client: {e}')
    finally:
        client_socket.close()
        remote_socket.close()

def start_server():
    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)  # ソケットの再利用
    server_socket.bind((LOCAL_HOST, LOCAL_PORT))
    server_socket.listen(5)

    with ThreadPoolExecutor(max_workers=MAX_THREADS) as executor:
        logging.info(f'Server listening on {LOCAL_HOST}:{LOCAL_PORT}')

        while True:
            client_socket, addr = server_socket.accept()
            executor.submit(handle_client, client_socket)

if __name__ == '__main__':
    start_server()
