<?php

class Pluginpasswd extends Plugin {

	function Pluginpasswd(){}

	function init(){
		$this->registerHook('server.dialog.general.setup.getincludes');
		$this->registerHook('server.index.load.dialog.after');
	}

	function execute($eventID, &$data){
		global $_GET;

/* Ensure that this only takes place if task is explicitly open settings, just to trigger on open is a maybe a
   bit to much risk */

		if ($_GET["task"] == "open_settings") {
	    	    switch($eventID){
			case "server.index.load.dialog.after":
				$this->dialogLoadAfter($data);
				break;
			case "server.dialog.general.setup.getincludes":
				$this->dialogGetIncludes($data);
				break;
		    };
		};
	}
/* Include the JavaScript that handles the page submit
*/
	function dialogGetIncludes(&$data) {
		if ($data["task"] != "open") return;
		$data["includes"][] = $this->getPluginPath(). "tabs/pwdchange.js";
	}
/* Adding a tab after page html content got loaded
*/
	function dialogLoadAfter(&$data) {
		global $tabbar;
		if (!is_object($tabbar) ||
		    !is_array($tabbar->tabs) ||
		    !array_key_exists("preferences",$tabbar->tabs)) return;
		textdomain('plugin_passwd');
		require_once($this->getPluginPath(). "tabs/pwdchange.php");
		$tabbar->beginTab("pwdchange");
		pwdchange_settings_html();
		$tabbar->endTab();
		textdomain('zarafa');
	}

}
?>
