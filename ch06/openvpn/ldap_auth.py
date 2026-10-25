# ldap_auth.py
import sys
from ldap3 import Server, Connection, ALL

ldap_server = 'ldap.example.co.jp'  # ①
ldap_user_dn = 'cn=Manager,dc=example,dc=jp' #②
ldap_password = 'PASSWORD' #③
user_dn_template = 'uid={},ou=People,dc=example,dc=jp' #④

def ldap_auth(username, password):
    try:
        server = Server(ldap_server, get_info=ALL)
        conn = Connection(server, ldap_user_dn, ldap_password, auto_bind=True) #⑤
        user_dn = user_dn_template.format(username) #⑥
        if conn.bind():#⑦
            user_conn = Connection(server, user_dn, password, auto_bind=True) #⑧
            if user_conn.bind():
                return True
            else:
                print("User auth failed.")
                return False
    except Exception as e:
        print("LDAP error:", e)
        return False
    finally:
        if conn and not conn.closed:
            conn.unbind()

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python ldap_auth.py <file>")
        sys.exit(1)

    filename = sys.argv[1]
    fp = open(filename)
    data = fp.readlines()
    fp.close()
    username = data[0].rstrip()
    password = data[1].rstrip()

    if ldap_auth(username, password):
        sys.exit(0)
    else:
        sys.exit(1)
