<?php
session_start();
$db_hostname = 'localhost';
$username = 'root';
$password = 'northy';
$db = 'erg_diax';
$connection = mysql_connect($db_hostname,$username,$password) or die ("Database Service is unavailable");
mysql_select_db($db,$connection);
require_once("includes/basics.php");
