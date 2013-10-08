<?php
// configuration file for dialogs/pwdchange.php

// this is handled in php/plugin.passwd.php
define("PLUGIN_PASSWD_USER_DEFAULT_ENABLE", true);

class PluginpasswdConfiguration
{
	// define, if this zarafa-installation uses ldap
	private $method = "ldap";

	// basedn, to search for users dn
	private $basedn = "dc=bitbone,dc=de";

	// ldap server uri
	// examples: "ldapi:///" or "localhost" or "127.0.0.1"
	private $uri = "localhost";

	function get_basedn () {
		return $this->basedn;
	}

	function get_uri () {
		return $this->uri;
	}

	function get_method () {
		return $this->method;
	}

}
/*
	vim:ts=2:sw=2:noet:
*/
?>
