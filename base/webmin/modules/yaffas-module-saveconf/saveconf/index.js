function SaveConf() {
	var create = new YAHOO.widget.Button("create");

	create.on("click", function() {
		window.open("/saveconf/create.cgi");
		window.close();
	});
}

SaveConf.prototype.savedForm = function(url) {
	switch(url) {
		case "restore.cgi":
			Yaffas.ui.resetTab();
		break;
	}
	
}

module = new SaveConf();
