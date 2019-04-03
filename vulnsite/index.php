<?php
// NOTE: This is a purposly insecure website, designed to test "TheHaywireHax: webrecon".
// Do no run on anything other then 127.0.0.1
if ($_SERVER["REQUEST_URI"] !== "/") {
  http_response_code(404);
  die("404 Not Found");
}
if (isset($_GET["cmd"])) {
  echo "<pre>".shell_exec($_GET["cmd"])."</pre>";
}
if (isset($_GET["admin"])) {
  $admin = $_GET["admin"];
  if ($admin) {
    echo "Hello Admin!";
  }
}
if (isset($_GET["reflect"])) {
  echo $_GET["reflect"];
}
if (isset($_POST["login"])) {
  if (($_POST["username"] == "root") && ($_POST["password"] == "toor")) {
    echo "<h1>Hi root</h1>";
  }
}
?>
<!DOCTYPE html>
<html lang="en" dir="ltr">
  <head>
    <meta charset="utf-8">
    <title>Insecure Chat</title>
  </head>
  <body>
    <form class="" action="" method="post">
      <input type="text" name="username" value="">
      <input type="password" name="password" value="">
      <input type="submit" name="login" value="Login">
    </form>
  </body>
</html>
