<?php
session_start();
if (!isset($_SESSION['username'])) {
header("Location: index.php");
exit();
}
$username = $_SESSION['username'];
$currentPassword = $_SESSION['password'];
if ($_SERVER['REQUEST_METHOD'] == 'POST') {
if ($_POST['csrf_token'] !== $_SESSION['_csrf_token'])
{
echo "Invalid CSRF token";
exit();
}
$newPassword = htmlspecialchars($_POST['newPassword'], ENT_QUOTES, 'UTF-8');
$ldapUrl = "ldap://192.168.0.10";
$baseDn = "ou=People,dc=example,dc=co,dc=jp";
$bindDn = "uid={$username},{$baseDn}";
// LDAP接続
$ldapConn = ldap_connect($ldapUrl);
ldap_set_option($ldapConn, LDAP_OPT_PROTOCOL_VERSION, 3);
if (!@ldap_bind($ldapConn, $bindDn, $currentPassword)) {
echo "Failed to bind to LDAP server";
error_log("LDAP bind failed for user: $username during password update");
exit();
}
// 新しいパスワードのハッシュを作成
$salt = substr(str_shuffle(str_repeat('ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789', 8)), 0, 8);
$cryptedPassword = (string) crypt($newPassword, '$6$' . $salt);
$ntPassword = strtoupper(hash('md4', iconv('UTF-8', 'UTF-16LE', $newPassword)));
// LDAPエントリを更新
$entry = array();
$entry['userPassword'] = "{CRYPT}$cryptedPassword";
$entry['sambaNTPassword'] = $ntPassword;
$entry['sambaPwdLastSet'] = time();
if (ldap_modify($ldapConn, $bindDn, $entry)) {
echo "Password updated successfully!";
} else {
echo "Failed to update password.";
}
ldap_close($ldapConn);
// 自動で画面遷移するためのJavaScript
echo '<script>
setTimeout(function() {
window.location.href = "index.php";
}, 3000); // 3秒待ってからリダイレクト
</script>';
echo 'You will be redirected to the login page in 3 seconds.';
} else {
?>
<!DOCTYPE html>
<html>
<head>
<title>Update Password</title>
<link rel="stylesheet" type="text/css" href="css/styles.css">
</head>
<body>
<header>
<div class="container">
<h1>Update Your Password</h1>
</div>
</header>
<div class="container">
<form action="" method="POST">
<input type="hidden" name="csrf_token" value="<?php echo $_SESSION['_csrf_token']; ?>">
New Password: <input type="password" name="newPassword" required><br>
<input type="submit" value="Update Password">
</form>
</div>
</body>
</html>
<?php
}
?>
