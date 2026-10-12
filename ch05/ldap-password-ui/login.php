<?php
session_start();
if ($_POST['csrf_token'] !== $_SESSION['_csrf_token'])
{
echo "Invalid CSRF token";
exit();
}
$username = htmlspecialchars($_POST['username'], ENT_QUOTES, 'UTF-8');
$password = htmlspecialchars($_POST['password'], ENT_QUOTES, 'UTF-8');
$ldapUrl = "ldap://192.168.0.10";
$baseDn = "ou=People,dc=example,dc=co,dc=jp";
$bindDn = "uid={$username},{$baseDn}";
// LDAP接続
$ldapConn = ldap_connect($ldapUrl);
ldap_set_option($ldapConn, LDAP_OPT_PROTOCOL_VERSION, 3);
if (!@ldap_bind($ldapConn, $bindDn, $password)) {
error_log("LDAP bind failed for user: $username");
echo "Invalid credentials";
exit();
}
session_regenerate_id(true);
$_SESSION['username'] = $username;
$_SESSION['password'] = $password;
header("Location: update_password.php");
ldap_close($ldapConn);
?>
