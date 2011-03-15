function Support() {
	var btn = new YAHOO.widget.Button("dlsupport");
	
	btn.on("click", function() {
		window.open("/support/save_support_infos.cgi");
		window.close();
	});
}

module = new Support();
