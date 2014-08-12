<?php

session_start();

$lang = getenv("HTTP_ACCEPT_LANGUAGE");
$set_lang = explode(',', $lang);

if (isset($_POST['lang'])) {
    $_SESSION['lang'] = $_POST['lang'];
} else {
    $_SESSION['lang'] = $set_lang[0];
}

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

/**
 * Compares two strings.
 *
 * This method implements a constant-time algorithm to compare strings.
 *
 * Taken from Symfony:
 * https://github.com/symfony/security-core/blob/e76be03b0a56d41c20b9027219593e31e0faa571/Util/StringUtils.php
 *
 * @param string $knownString The string of known length to compare against
 * @param string $userInput   The string that the user can control
 *
 * @return bool    true if the two strings are the same, false otherwise
 */
function hash_equals_symfony($knownString, $userInput) {
    // Prevent issues if string length is 0
    $knownString .= chr(0);
    $userInput .= chr(0);
    $knownLen = strlen($knownString);
    $userLen = strlen($userInput);

    // Set the result to the difference between the lengths
    $result = $knownLen - $userLen;

    // Note that we ALWAYS iterate over the user-supplied length
    // This is to prevent leaking length information
    for ($i = 0; $i < $userLen; $i++) {
        // Using % here is a trick to prevent notices
        // It's safe, since if the lengths are different
        // $result is already non-0
        $result |= (ord($knownString[$i % $knownLen]) ^ ord($userInput[$i]));
    }

    // They are only identical strings if $result is exactly 0...
    return 0 === $result;
}

$hash_equals = "hash_equals";
if (!function_exists("hash_equals")) {
    // php-5.6 has native support; if the function is not
    // available, use the above one from symfony
    $hash_equals .= "_symfony";
}

function send_result($status, $msg, $err = "") {

    print json_encode(array(
        "status" => $status,
        "message" => $msg,
        "error" => $err));
}

function ssha_encode($password){
    $salt = pack("CCCC", mt_rand(), mt_rand(), mt_rand(), mt_rand());
    $hash = "{SSHA}" . base64_encode(pack("H*", sha1($password . $salt)) . $salt);
    return $hash;
}

function ssha_password_verify($hash, $password){
    global $hash_equals;
    // Verify SSHA hash
    $ohash = base64_decode(substr($hash, 6));
    $osalt = substr($ohash, 20);
    $ohash = substr($ohash, 0, 20);
    $nhash = pack("H*", sha1($password . $osalt));
    return $hash_equals($ohash, $nhash);
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
require_once "../config.inc.php";
$config = new PluginpasswdConfiguration();

// check if we should use ldap or zarafa-admin
$method = $config->get_method ();

if ($method == "ldap") {

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
    ldap_set_option($ds, LDAP_OPT_PROTOCOL_VERSION, 3);

    $ldap_error = ldap_errno($ds);
    if ($ldap_error == 0) {

        if (!$config->is_bindanon()) {
            $bind = ldap_bind($ds, $config->get_binduser(),$config->get_binduserpw());
            if (!$bind) {
                send_result ("failure", _("Password update failed. Please contact the system administrator."), "Binding to the ldap server failed.");
                exit ("Bind with special user failed");
            }
        }

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
                    $checkpw = ssha_password_verify($password_hash, $newpw1);

                    if (!$checkpw) {
                        send_result ("failure", _("Password update failed. Please contact the system administrator."), "The password verification failed");
                        exit ("Hash Password error");
                    }

                    $entry = array('userPassword' => $password_hash);
                    $return_mod = ldap_modify ($ds, $dn, $entry);
                    $ldap_error = ldap_errno($ds);
                    if ($ldap_error == 0) {

                        send_result ("success", _("Password updated correctly. You will need to login again."));
                    }
                    else {

                        // TODO: acknowledge the ldap error codes to give a more
                        // specific error report to the user
                        send_result ("failure", _("Password update failed. Please contact the system administrator."));
                    }
                }
                else {

                    if (($newpw1 == "") || ($newpw1 == "")) { send_result ("failure", _("New password is empty")); }
                        if (!check_password($newpw1)) { send_result ("failure", _("Password too weak.")); }
                        else { send_result ("failure", _("New passwords don't match.")); }
                }

            }
            else {
                if ($ldap_error == 49) {
                    send_result ("failure", _("Old password is wrong."));
                }
                else {
                    send_result ("failure", _("Could not bind to ldap."));
                }
            }
        }
        else {
            send_result ("failure", _("Password update failed. Please contact the system administrator."), "Could not find a user with name $uid");
        }

    } else {
        send_result ("failure", _("Password update failed. Please contact the system administrator.", "Could not bind to the ldap server"));
    }

    // release ldap-bind
    ldap_unbind($ds);
}
else if ($method == "ad") {

    if (
        ($newpw1 == $newpw2) &&
        ($newpw1 != NULL) &&
        ($newpw1 != "") &&
        (check_password($newpw1))
    ) {

        $descriptorspec = array(
            0 => array("pipe", "r"),  // stdin is a pipe that the child will read from
            1 => array("pipe", "w"),  // stdout is a pipe that the child will write to
            2 => array("pipe", "w") // stderr is a file to write to
        );

        $process = proc_open("/usr/bin/smbpasswd -U ".escapeshellarg($username)." -r ".escapeshellarg($config->get_uri())." -s", $descriptorspec, $pipes, "/tmp");
        fwrite($pipes[0], $password."\n");
        fwrite($pipes[0], $newpw1."\n");
        fwrite($pipes[0], $newpw1."\n");

        $msg = fread($pipes[2], 1024);
        $msg = rtrim($msg);

        $ret = proc_close($process);

        if ($ret == 0) {
            send_result ("success", _("Password updated correctly. You will need to login again."));
        }
        else {
            send_result ("failure", _("Password update failed. Please contact the system administrator."), $msg);
        }
    }
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
            send_result ("success", _("Password updated correctly. You will need to login again."));
        } else {
            send_result ("failure", _("Password update failed. Please contact the system administrator."));
        }
    } else {
        if ($newpw1 != $newpw2) send_result ("failure", _("New passwords don't match."));
        if ($username == null) send_result ("failure", _("Username not found"));
        if ($newpw1 == null && $newpw2 == null) send_result ("failure", _("New password is empty"));
        if (!check_password($newpw1)) send_result ("failure", _("Password too weak."));
    }
}
putenv('LC_ALL='.$_SESSION['lang']);
setlocale(LC_ALL, $_SESSION['lang']);
?>
