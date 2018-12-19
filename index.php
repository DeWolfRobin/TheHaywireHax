<?php
$whitelist = ['/','/admin'];
echo $_SERVER['REQUEST_URI'];
if(in_array($_SERVER['REQUEST_URI'], $whitelist)){
echo ' hi';
} else {
http_response_code(404);
die();
}
?>
