Aliases = function() {
	this.table = null;
	this.menu = null;
	this.setupTable();
    //this.changeAliasType();
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
		Yaffas.ui.openTab("/mailalias/edit.cgi", {alias: r[0][0]}, function() { this.changeAliasType() }.bind(this));
	}
}

Aliases.prototype.savedForm = function(url, args) {
    switch(url) {
        case "add.cgi":
            Yaffas.ui.resetTab();
            module.changeAliasType();
            break;
        case "edit.cgi":
            Yaffas.ui.closeTab();
            break;
    }
    this.table.reload();
}

Aliases.prototype.changeAliasType = function() {
    var tab = Yaffas.ui.tabs.get("activeTab").get("contentEl");
    var from = tab.select("select#aliastype")[0];

    var manual = tab.select("tr#row-manual")[0];
    var user = tab.select("tr#row-user")[0];

    var current = "";

    if (typeof from !== null) {
        current = from.value;
    }
    else {
        return;
    }

    if (current === "user") {
        manual.hide();
        user.show();
    }
    else {
        manual.show();
        user.hide();
    }
}

Aliases.prototype.cleanup = function() {
	this.menu.destroy();
}

module = new Aliases();
