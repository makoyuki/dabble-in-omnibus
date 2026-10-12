import socket
import logging
import subprocess
from concurrent.futures import ThreadPoolExecutor

# 設定
LOCAL_HOST = '0.0.0.0'
LOCAL_PORT = 9110
REMOTE_HOST = 'localhost'  # dovecotを構築したのでlocalにする
REMOTE_PORT = 110
MAX_THREADS = 100
TIMEOUT = 60  # タイムアウト時間を短く

# ログ設定
logging.basicConfig(
    filename='/var/log/pop3proxy.log',
    level=logging.INFO,  # <--- INFOに変更
    format='%(asctime)s - %(levelname)s - %(message)s'
)

def hex_log(data):
    return ' '.join(f'{b:02x}' for b in data)

def recv_until(sock, terminator, buffer_size=4096):  # buffer_sizeを小さく
    data = b''
    while True:
        try:
            chunk = sock.recv(buffer_size)
            if not chunk:
                break
            data += chunk
            if terminator in data:
                break
        except socket.timeout:
            logging.error("Socket timeout while receiving data")
            break
        except Exception as e:
            logging.error(f"Error receiving data: {e}")
            break
    return data

def recv_multiple_lines(sock):
    data = b''
    while True:
        try:
            chunk = sock.recv(4096)  # buffer_sizeを小さく
            if not chunk:
                break
            data += chunk
            if b'\r\n.\r\n' in data:
                break
        except socket.timeout:
            logging.error("Socket timeout")
            break
        except Exception as e:
            logging.error(f"Socket error: {e}")
            break
    return data

def recv_response(sock, multiline):
    """サーバの応答を受け取る。複数行の応答(+OK のとき)は終端の「.」の行まで受け取る"""
    data = recv_until(sock, b'\r\n')
    if multiline and data.startswith(b'+OK'):
        while b'\r\n.\r\n' not in data:
            chunk = sock.recv(4096)
            if not chunk:
                break
            data += chunk
    return data

def is_multiline(client_data):
    """複数行の応答が返るコマンドか(RETR/TOPは常に、LIST/UIDLは引数なしのとき)"""
    words = client_data.strip().split()
    if not words:
        return False
    cmd = words[0].upper()
    return cmd in (b'RETR', b'TOP') or (cmd in (b'LIST', b'UIDL', b'CAPA') and len(words) == 1)

def log_client_data(client_data):
    """クライアントからのコマンドをログに書く(PASSのパスワードは書かない)"""
    if client_data.upper().startswith(b'PASS'):
        logging.info("Data from client: PASS ********")
    else:
        logging.info(f"Data from client: {client_data.decode(errors='ignore').strip()}")

def scan_with_clamav(data):
    """ClamAVでウイルススキャン"""
    process = subprocess.run(['clamscan', '--stdout', '--no-summary', '-'], input=data, capture_output=True)
    return process.returncode, process.stdout.decode()

def scan_with_spamc(data):
    """Spamcでスパムスキャン"""
    process = subprocess.run(['spamc'], input=data, capture_output=True)
    return process.returncode, process.stdout

def handle_client(client_socket):
    remote_socket = None
    try:
        logging.info("Creating remote socket")
        remote_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        remote_socket.settimeout(TIMEOUT)

        logging.info(f"Connecting to {REMOTE_HOST}:{REMOTE_PORT}")
        remote_socket.connect((REMOTE_HOST, REMOTE_PORT))
        logging.info(f"Connected to {REMOTE_HOST}:{REMOTE_PORT}")

        # 初期ウェルカムメッセージの受信と転送
        welcome_message = recv_until(remote_socket, b'\r\n')
        logging.info(f"Received welcome message from server: {welcome_message}")
        client_socket.sendall(welcome_message)

        while True:
            logging.info("Receiving data from client")
            try:
                client_data = client_socket.recv(4096)
                if not client_data:
                    logging.info("No data received from client, closing connection")
                    break

                log_client_data(client_data)
                remote_socket.sendall(client_data)

                response_data = recv_response(remote_socket, is_multiline(client_data))

                # メールデータ(RETRの応答)をウイルスチェックとスパムチェックする
                if client_data.upper().startswith(b'RETR') and response_data.startswith(b'+OK'):
                    status, _, message = response_data.partition(b'\r\n')
                    if message.endswith(b'\r\n.\r\n'):
                        message = message[:-3]  # 終端の「.」の行は検査に含めない
                    logging.info("Scanning email data with ClamAV and SpamAssassin")
                    clamav_retcode, clamav_output = scan_with_clamav(message)
                    spamc_retcode, spamc_output = scan_with_spamc(message)

                    if clamav_retcode == 1 or 'FOUND' in clamav_output:
                        logging.warning("Virus detected by ClamAV")
                        # 必要に応じてメールをブロックまたは警告を追加する
                        response_data = b'-ERR Virus detected\r\n'
                    elif b'X-Spam-Flag: YES' in spamc_output:
                        logging.warning("Spam detected by SpamAssassin")
                        # 必要に応じてスパムメールの処理を行う。ここではSpamAssassinがヘッダーを追加したメールに差し替える例
                        response_data = status + b'\r\n' + spamc_output + b'.\r\n'

                logging.info(f"Data received from server: {len(response_data)} bytes")
                logging.debug(f"Data received from server: {response_data.decode(errors='ignore')} (hex: {hex_log(response_data)})")

                client_socket.sendall(response_data)
            except socket.timeout:
                logging.error("Socket timeout while receiving data from client")
                break
            except socket.error as e:
                logging.error(f"Socket error while receiving data from client: {e}")
                break
            except Exception as e:
                logging.error(f"Error handling client data: {e}")
                break
    except socket.timeout:
        logging.error("Connection to remote server timed out")
    except Exception as e:
        logging.error(f"Error handling client: {e}")
    finally:
        logging.info("Closing sockets")
        try:
            if remote_socket:
                remote_socket.shutdown(socket.SHUT_RDWR)
                remote_socket.close()
        except Exception as e:
            logging.error(f"Error closing remote socket: {e}")
        try:
            client_socket.shutdown(socket.SHUT_RDWR)
            client_socket.close()
        except Exception as e:
            logging.error(f"Error closing client socket: {e}")

def start_server():
    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server_socket.bind((LOCAL_HOST, LOCAL_PORT))
    server_socket.listen(5)

    with ThreadPoolExecutor(max_workers=MAX_THREADS) as executor:
        logging.info(f'Server listening on {LOCAL_HOST}:{LOCAL_PORT}')

        while True:
            client_socket, addr = server_socket.accept()
            logging.info(f'Accepted connection from {addr}')
            executor.submit(handle_client, client_socket)

if __name__ == '__main__':
    start_server()
