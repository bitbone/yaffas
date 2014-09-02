#!/usr/bin/php
<?php

include('/usr/share/php/mapi/mapi.util.php');
include('/usr/share/php/mapi/mapidefs.php');
include('/usr/share/php/mapi/mapicode.php');
include('/usr/share/php/mapi/mapitags.php');
include('/usr/share/php/mapi/mapiguid.php');
include('/usr/share/zarafa-webaccess/config.php');
include('/usr/share/zarafa-webaccess/server/core/class.settings.php');
include('/usr/share/zarafa-webaccess/server/core/class.mapisession.php');
include('/usr/share/zarafa-webaccess/server/core/class.conversion.php');
include('/usr/share/zarafa-webaccess/server/util.php');

$adminusername = "SYSTEM";
$adminpassword = "";
define("SERVER", "file:///var/run/zarafa");

$user = $argv[1];
$file = $argv[2];

$GLOBALS["mapisession"] = new MAPISession();
$GLOBALS["mapisession"]->Logon($user, "", "file:///var/run/zarafa");


$GLOBALS["settings"] = new Settings();

$GLOBALS["settings"]->Init();
$GLOBALS["settings"]->retrieveSettings();



if ($file == "disable") {
	$GLOBALS["settings"]->set("/outofoffice/set", "false");
}
elseif ($file == "json") {
	print json_encode($GLOBALS["settings"]->get("/outofoffice"));
}
elseif (file_exists($file)) {
	$content = file($file) or die("Could not open file $file.");
	$subject = array_shift($content);	

	$GLOBALS["settings"]->set("/outofoffice/set", "true");
	$GLOBALS["settings"]->set("/outofoffice/subject", $subject);
	$GLOBALS["settings"]->set("/outofoffice/message", implode($content));
	$GLOBALS["settings"]->set("/outofoffice_change_id", rand());
}
else {
	print_r($GLOBALS["settings"]->get("/outofoffice"));
}

?>
