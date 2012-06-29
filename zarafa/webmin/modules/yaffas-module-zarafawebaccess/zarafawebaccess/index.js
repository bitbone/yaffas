function ZarafaWebaccess(){

	this.setupTable();
}

ZarafaWebaccess.prototype.setupTable = function() {
	var myColumnDefs = [
    {
        key: "option",
        label: _("lbl_option"),
        sortable: true,
		hidden: true,
	}, {
		key: "label",
		label: _("lbl_option"),
		sortable: true,
	}, {
        key: "state",
        label: _("lbl_state"),
        sortable: true,
		formatter: function(e, record, column, data){
			var disabled = "";

			e.innerHTML = "<input type='checkbox' "+((data === 1) ? "checked" : "")+" />";

			YAHOO.util.Event.addListener(e.getElementsByTagName("input")[0], "click", function() {
				console.log("clicked %s %s", this.checked, record.getData().option);
				Yaffas.ui.submitURL("/zarafawebaccess/options.cgi", {type: record.getData().option, value: this.checked ? "true" : "false"})
			})
    	}
    }];
	this.table = new Yaffas.Table({
		container: "options",
		columns: myColumnDefs,
		url: "/zarafawebaccess/options.cgi",
		sortColumn: 0
	});
}

ZarafaWebaccess.prototype.savedForm = function(url){
    switch (url) {
        case "options.cgi":
            this.table.reload();
            break;
    }
}


module = new ZarafaWebaccess();
