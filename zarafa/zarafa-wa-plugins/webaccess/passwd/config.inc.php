<?php
// configuration file for dialogs/pwdchange.php

class Configuration
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
?>

