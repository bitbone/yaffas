function Resources(){
    this.table = null;
    this.menu = null;
    this.setupTable();
}

Resources.prototype.editResource = function(){
    var r = this.table.selectedRows();
    
    if (r.length > 0) {
        Yaffas.ui.openTab("/zarafaresources/index.cgi", {
            action: "edit",
            resource: r[0][0]
        });
    }
}

Resources.prototype.deleteResource = function(){
    var r = this.table.selectedRows();
    
    if (r.length > 0) {
        var d = new Yaffas.Confirm(_("lbl_delresource"), _("lbl_delresource_question"), function(){
            Yaffas.ui.submitURL("/zarafaresources/delete.cgi", {
                resource: r[0][0]
            });
        });
		d.show();
    }
}

Resources.prototype.formatColumn = function(e, record, column, data){
	e.innerHTML = data ? _("lbl_yes") : _("lbl_no");
}

Resources.prototype.setupTable = function(){
    var columns = [{
        key: "name",
        label: _("lbl_resource"),
        sortable: true,
    }, {
        key: "description",
        label: _("lbl_description"),
        sortable: true,
    }, {
        key: "type",
        label: _("lbl_resource_type"),
        sortable: true,
    }, {
        key: "capacity",
        label: _("lbl_capacity"),
        sortable: true,
    }, {
        key: "conflicts",
        label: _("lbl_decline_conflict"),
        sortable: true,
		formatter: this.formatColumn
    }, {
        key: "recurring",
        label: _("lbl_decline_recurring"),
        sortable: true,
		formatter: this.formatColumn
    }];
    
    this.table = new Yaffas.Table({
        container: "table",
        url: "/zarafaresources/resources.cgi",
        "columns": columns
    });
    
    var menuitems = [{
        text: _("lbl_editresource"),
        onclick: {
            fn: this.editResource.bind(this)
        },
    }];

	if (auth_type() === "local LDAP") {
		menuitems.push({
			text: _("lbl_delresource"),
			onclick: {
				fn: this.deleteResource.bind(this)
			},
		});
	}
    
    this.menu = new Yaffas.Menu({
        container: "menu",
        trigger: "table",
        items: menuitems
    });
    
    
}

Resources.prototype.confirmation = function(url, args, submit){
    switch (url) {
        case "file.cgi":
            if (args) {
                var d = new Yaffas.Confirm(_("lbl_title"), _("lbl_question"), submit);
                d.show();
                return true;
            }
    }
    return false;
}

Resources.prototype.savedForm = function(url){
    switch (url) {
        case "create.cgi":
            Yaffas.ui.resetTab();
            this.table.reload();
            break;
        case "edit.cgi":
            Yaffas.ui.closeTab();
            this.table.reload();
			break;
        case "delete.cgi":
            this.table.reload();
			break;
    }
}

Resources.prototype.cleanup = function(){
    this.menu.destroy();
    this.menu = null;
}

module = new Resources();
