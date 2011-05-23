Aliases = function() {
	this.table = null;
	this.menu = null;
	this.setupTable();
}

Aliases.prototype.confirmation = function(url, args, submit) {
	switch(url) {
		case "edit.cgi":
			if (args["del_to"]) {
				var tab = Yaffas.ui.tabs.get("activeTab").get("contentEl");
				var from = tab.select("input#from")[0];
				args["from"] = from.value;
				submit();
				return true;
			}
		break;
	}
}

Aliases.prototype.setupTable = function() {

    var menuitems = [
	{
		text: _("lbl_changealias"),
		onclick: {
			fn: this.editAlias.bind(this)
		}
	}, {
        text: _("lbl_del"),
        onclick: {
            fn: this.deleteAlias.bind(this)
        }
    }
	];
		
	var columns = [
    {
        key: "alias",
        label: _("lbl_mailalias"),
        sortable: true
    }, {
        key: "user",
        label: _("lbl_user"),
        sortable: true,
    }/*, {
        key: "folder",
        label: _("lbl_destination_dir"),
        sortable: true
    }*/
	];
		
	this.table = new Yaffas.Table({
		container: "table",
		columns: columns,
		url: "/mailalias/aliases.cgi",
		sortColumn: 1
	});
	
	this.menu = new Yaffas.Menu({container: "menu", trigger: "table", items: menuitems});
}

Aliases.prototype.deleteAlias = function() {
	var r = this.table.selectedRows();
	
	if (r.length > 0) {
		var c = new Yaffas.Confirm(_("lbl_delalias"), _("lbl_delete_confirm")+dlg_arg(r[0][0]), function() {
			Yaffas.ui.submitURL("/mailalias/delete.cgi", {
				delete_me: r[0][0]
			});
		});
		c.show();
	}
}

Aliases.prototype.editAlias = function() {
	var r = this.table.selectedRows();
	
	if (r.length > 0) {
		Yaffas.ui.openTab("/mailalias/edit.cgi", {alias: r[0][0]});
	}
}

Aliases.prototype.savedForm = function(url, args) {
	switch(url) {
		case "delete.cgi":
			this.table.reload();
			break;
		case "add.cgi":
			Yaffas.ui.resetTab();
			this.table.reload();
			break;
		case "edit.cgi":
			if (args["to"]) {
                if (YAHOO.lang.isArray(args.to)) {
                    for (var i = 0; i < args.to.length; ++i) {
                        Yaffas.list.add("del_to", args.to[i], "/mailalias/edit.cgi");
                    }
                }
                else {
                    Yaffas.list.add("del_to", args.to, "/mailalias/edit.cgi");
                }
				Yaffas.ui.resetTab();
			}
			else if (args["del_to"]) {
				Yaffas.list.remove("del_to", args.del_to);
			}
			else {
				Yaffas.ui.closeTab();
			}
			this.table.reload();
			break;
	}
}

Aliases.prototype.cleanup = function() {
	this.menu.destroy();
}

module = new Aliases();
