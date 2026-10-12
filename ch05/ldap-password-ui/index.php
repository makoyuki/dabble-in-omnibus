<?php
session_start();
if (empty($_SESSION['_csrf_token'])) {
$_SESSION['_csrf_token'] = bin2hex(random_bytes(32));
}
$csrf_token = $_SESSION['_csrf_token'];
?>
<!DOCTYPE html>
<html>
<head>
<title>Login</title>
<link rel="stylesheet" type="text/css" href="css/styles.css">
</head>
<body>
<header>
<div class="container">
<h1>LDAP Password Management</h1>
</div>
</header>
<div class="container">
<form action="login.php" method="POST">
<input type="hidden" name="csrf_token" value="<?php echo $csrf_token; ?>">
Username: <input type="text" name="username" required><br>
Password: <input type="password" name="password" required><br>
<input type="submit" value="Login">
</form>
</div>
</body>
</html>
