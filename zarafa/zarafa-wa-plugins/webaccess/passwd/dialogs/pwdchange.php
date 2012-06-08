<?php

// init gettext
$domain = "passwd";
if ($_SESSION['lang'] != "en_EN") {
	putenv('LC_ALL='.$_SESSION['lang']);
	setlocale(LC_ALL, $_SESSION['lang']);
} else {
	putenv('LC_ALL=en_US.UTF-8');
	setlocale(LC_ALL, 'en_US.UTF-8');
}
bindtextdomain ($domain, "plugins/passwd/lang/");
textdomain ($domain);

function getDialogTitle(){
	return _("Password change result");
}

function getBody() {

// debug
//error_reporting (E_ALL);
//ini_set('error_log','/var/log/php_error.log');

	$username = (isset($_POST["pwdchange_username"])? $_POST["pwdchange_username"] : null);
	$password = (isset($_POST["pwdchange_oldpw"])   ? $_POST["pwdchange_oldpw"]    : null);
	$newpw1   = (isset($_POST["pwdchange_newpwd1"]) ? $_POST["pwdchange_newpwd1"]  : null);
	$newpw2   = (isset($_POST["pwdchange_newpwd2"]) ? $_POST["pwdchange_newpwd2"]  : null);

	// get path for this plugin
	$pathname = dirname($_SERVER['SCRIPT_FILENAME']);

	// get some basic configuration
	include $pathname. '/plugins' .'/'. 'passwd' .'/'. 'config.inc.php';
	$config = new Configuration();

	// check if we should use ldap or zarafa-admin
	$use_ldap = $config->get_method ();

	if ($use_ldap) {

		//
		// use ldap
		//

		// get the users uid
		if (strpos($username, "@")) {
			// i assume, that user logs in with uid@ou
			$a_rdn = explode ("@", $username);
			$uid = $a_rdn[0];
		} else {
			// user logs in with his uid
			$uid = $username;
		}

		// connect to ldap directory
		$ds = ldap_connect($config->get_uri());
		$ldap_error = ldap_errno($ds);
		if ($ldap_error == 0) {

			// lookup the users dn
			$sr = ldap_search (
				$ds,                   // connection-identify
				$config->get_basedn(), // basedn
				"uid=".$uid,           // search filter
				array("dn")            // needed attributes. we need the dn
			);
			if ($sr) {

				$info = ldap_get_entries($ds, $sr);
				$dn = $info[0]['dn'];

				// bind to ldap directory
				ldap_set_option($ds, LDAP_OPT_PROTOCOL_VERSION, 3);
				$bind = ldap_bind($ds, $dn, $password);
				$ldap_error = ldap_errno($ds);
				if ($ldap_error == 0) {

					// Connection and bind are established, now try to change password
					if (
						($newpw1 == $newpw2) && 
						($newpw1 != NULL) && 
						($newpw1 != "") &&
						(check_password($newpw1))
					) {
			
						$password_hash = ssha_encode ($newpw1);
						$entry = array('userPassword' => $password_hash);
						$return_mod = ldap_modify ($ds, $dn, $entry);
						$ldap_error = ldap_errno($ds);
						if ($ldap_error == 0) {

							echo _("success: password update"); 
						}
						else {

							// TODO: acknowledge the ldap error codes to give a more
							// specific error report to the user
							echo _("failure: password update");
						}
					}
					else {
		
						if (($newpw1 == "") || ($newpw1 == "")) { echo _("failure: new password empty"); }
						if (!check_password($newpw1)) { echo _("failure: password weak"); }
						else { echo _("failure: new passwords dont match"); }
					}

				}
				else {
					if ($ldap_error == 49) {
							echo _("failure: old passwords wrong");
					}
					else {
						echo _("failure: could not bind to ldap");
					}
				}
			}
			else {
				echo _("failure: password update"); 
			}

		} else {
			echo _("failure: password update"); 
		}

		// release ldap-bind
		ldap_unbind($ds);
	}
	else {

		//
		// use zarafa-admin to change password
		// (this part is basically the original zarafa-passwd
		// plugin (and really unsecure))
		//

		$passwd_cmd = "/usr/bin/zarafa-passwd -u %s -o %s -p %s";
		if (
			($username != null) &&  
			($password != null) &&  
			($newpw1 != null) &&  
			($newpw2 == $newpw1) &&
			(check_password($newpw1))
		) {

			// all information correct, change password
			$mycmd = sprintf($passwd_cmd, $username, $password, $newpw1);
			exec($mycmd,$arrayout, $retval);
			if ($retval == 0) {
				echo _("success: password update");
			} else {
				echo _("failure: password update");
			}   
		} else {
			if ($newpw1 != $newpw2) echo _("failure: new passwords dont match");
			if ($username == null) echo _("failure: username not found");
			if ($newpw1 == null && $newpw2 == null) echo _("failure: new password empty");
			if (!check_password($newpw1)) echo _("failure: password weak");
		}   
	}
	putenv('LC_ALL='.$_SESSION['lang']);
	setlocale(LC_ALL, $_SESSION['lang']);
}

// 	create a ldap-password-hash from $text
function ssha_encode ($text) {
	$salt = "";
	for ($i=1;$i<=10;$i++) {
		$salt .= substr('0123456789abcdef',rand(0,15),1);
	}       
	$hash = "{SSHA}".base64_encode(pack("H*",sha1($text.$salt)).$salt);
	return $hash;
}       

// check passwords. They should meet the following criteria:
// - min. 8 chars, max. 20
// - contain caps und noncaps characters
// - contain numbers
// return FALSE if not all criteria are met
function check_password ($password) {
	if (preg_match("#.*^(?=.{8,20})(?=.*[a-z])(?=.*[A-Z])(?=.*[0-9]).*$#", $password)) {
		return TRUE;
	} else {
		return FALSE;
	}
}

// logout user
// TODO: Don't log out user when password didn't change.
function getJavaScript_onload(){
	echo "\t\t\t\t\twindow.setTimeout(\"parent.parentwindow.location.href='index.php?logout'\",5000);\n";
} 

?>
