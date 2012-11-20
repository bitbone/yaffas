function SNMPConf(){
}

SNMPConf.prototype.confirmation = function(url, args, submit) {
	var callback = {
		success: function(r) {
			var result = YAHOO.lang.JSON.parse(r.responseText);

			if (result.has_tag != 1) {
				// config file will be replaced, so ask for confirmation
				var d = new Yaffas.Confirm(
					_("lbl_confirm_replace_config_header"),
					_("lbl_confirm_replace_config_msg"),
					submit);
				d.show();
			} else {
				// no users will be deleted, so we proceed without asking
				submit();
			}
		},
		failure: Yaffas.ui.handleFailure,
		scope: this
	};

	YAHOO.util.Connect.asyncRequest("POST", "/snmpconf/check_yaffas_tag.cgi",
		callback, args);

	// delay submitting
	return true;
}

module = new SNMPConf();
