Certificate = function() {
}

/* wird anstatt submit aufgerufen */
Certificate.prototype.confirmation = function(url, args, submit) {
	switch (url) {
		case "view.cgi":
			var box = new Yaffas.Confirm(_("import_del"),
					       _("import_delquestion"),
					       submit);
			box.show();
			return true;
		default:
			return false;;
	}
}

/* wird nach abschluss von submit aufgerufen */
Certificate.prototype.savedForm = function(url, args) {
	if (args["service"] === "webmin" || args["service"] === "all" || args["del"] === "webmin.crt") {
		location.replace("/");
	}
	else {
		Yaffas.ui.reloadTabs();
	}
}

module = new Certificate();


