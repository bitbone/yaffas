function Netconf() {
	
	var items = document.getElementsByTagName("input");
	
	for (var i = 0; i < items.length; ++i) {
		if (YAHOO.lang.isString(items[i].id) && items[i].id.match(/newip-(.*)/)) {
			var name = items[i].id;
			name = name.replace(/newip-/, "");
			
			var btn = new YAHOO.widget.Button(items[i]);
			btn.on("click", function(name) {
				Yaffas.ui.openTab('/netconf/check_settings.cgi', {'new-ip': name});
			}.curry(name));
		}

		if (YAHOO.lang.isString(items[i].id) && items[i].id.match(/delete-(.*)/)) {
			var name = items[i].id;
			name = name.replace(/delete-/, "");
			
			var btn = new YAHOO.widget.Button(items[i]);
			btn.on("click", function(name) {
				Yaffas.ui.submitURL('/netconf/check_settings.cgi', {'mode': 'delete', 'device': name});
			}.curry(name));
		}
	}
	
}

Netconf.prototype.confirmation = function(url, args, submit) {
	switch(url) {
		case "check_settings.cgi":
		if (args["mode"] === "delete") {
			var d = new Yaffas.Confirm(_("lbl_delete_device"), _("lbl_really_delete")+dlg_arg(args["device"]), submit);
			d.show();
			return true;
		}
	}
	return false;
}

Netconf.prototype.savedForm = function(url, args) {
	if (args["mode"] === "new") {
		Yaffas.ui.reloadTabs();
	}
	
	if (args["mode"] === "delete") {
		Yaffas.ui.closeTab();
	}
}

module = new Netconf();
