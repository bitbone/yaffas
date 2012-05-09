function OrphanedStores(){
    this.table = null;
    this.menu = null;
    this.setupTable();
}

OrphanedStores.prototype.attachOrphanedStore = function(){
    var r = this.table.selectedRows();
    
    if (r.length > 0) {
        Yaffas.ui.openTab("/zarafaorphanedstores/index.cgi", {
            action: "attach",
            orphans: r[0][0]
        });
    }
}

OrphanedStores.prototype.publicOrphanedStore = function(){
    var r = this.table.selectedRows();
    
    if (r.length > 0) {
        var d = new Yaffas.Confirm(_("lbl_publicorphaned"), _("lbl_publicorphaned_question"), function(){
            Yaffas.ui.submitURL("/zarafaorphanedstores/public.cgi", {
                orphans: r[0][0]
            });
        });
		d.show();
    }
}

OrphanedStores.prototype.deleteOrphanedStore = function(){
    var r = this.table.selectedRows();
    
    if (r.length > 0) {
        var d = new Yaffas.Confirm(_("lbl_delorphaned"), _("lbl_delorphaned_question"), function(){
            Yaffas.ui.submitURL("/zarafaorphanedstores/delete.cgi", {
                orphans: r[0][0]
            });
        });
		d.show();
    }
}

OrphanedStores.prototype.setupTable = function(){
    var columns = [{
        key: "guid",
        label: _("lbl_guid"),
        sortable: true,
    }, {
        key: "username",
        label: _("lbl_username"),
        sortable: true,
    }, {
        key: "modified",
        label: _("lbl_modified"),
        sortable: true,
    }, {
        key: "size",
        label: _("lbl_size"),
        sortable: true,
    }, {
        key: "type",
        label: _("lbl_type"),
        sortable: true,
    }];
    
    this.table = new Yaffas.Table({
        container: "table",
        url: "/zarafaorphanedstores/orphanedstores.cgi",
        "columns": columns
    });

    var menuitems = [
	{
        text: _("lbl_deleteorphaned"),
        onclick: {
            fn: this.deleteOrphanedStore.bind(this)
	}
        },
	{
        text: _("lbl_attachorphaned"),
        onclick: {
            fn: this.attachOrphanedStore.bind(this)
	}
        },
	{
        text: _("lbl_publicorphaned"),
        onclick: {
            fn: this.publicOrphanedStore.bind(this)
	}
        },
    ];
 
    this.menu = new Yaffas.Menu({
        container: "menu",
        trigger: "table",
        items: menuitems
    });
}


OrphanedStores.prototype.confirmation = function(url, args, submit){
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

OrphanedStores.prototype.savedForm = function(url){
    switch (url) {
        case "public.cgi":
            this.table.reload();
            break;
        case "delete.cgi":
            this.table.reload();
			break;
    }
}


OrphanedStores.prototype.cleanup = function(){
    this.menu.destroy();
    this.menu = null;
}

module = new OrphanedStores();

