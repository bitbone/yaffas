function About(){
	this.tableload = null;
	this.tablemem = null;
	this.tabledf = null;
	
    this.setupTable();
	this.updater = new PeriodicalExecuter(this.reloadTables.bind(this), 30);
}

About.prototype.reloadTables = function() {
	this.tableload.reload();
	this.tablemem.reload();
	this.tabledf.reload();
}

About.prototype.formatMem = function(e, record, column, data){
	e.innerHTML = (data/1024).toFixed(2)+" MB";
}

About.prototype.setupTable = function(){
    var columns = [{
        key: "name",
        label: _("lbl_name"),
        sortable: true,
    }, {
        key: "ver",
        label: _("lbl_version"),
        sortable: true,
    }];
    this.table = new Yaffas.Table({
        container: "table",
        url: "/about/versions.cgi",
        "columns": columns
    });
    
    var columns_df = [{
        key: "filesystem",
        label: _("lbl_filesystem"),
        sortable: true,
    }, {
        key: "size",
        label: _("lbl_size"),
        sortable: true,
    }, {
        key: "used",
        label: _("lbl_used"),
        sortable: true,
    }, {
        key: "available",
        label: _("lbl_available"),
        sortable: true,
    }, {
        key: "used_percent",
        label: _("lbl_used_percent"),
        sortable: true,
    }, {
        key: "mountpoint",
        label: _("lbl_mount"),
        sortable: true,
    }];

    this.tabledf = new Yaffas.Table({
        container: "table-df",
        url: "/about/df.cgi",
        "columns": columns_df
    });
    
    var columns_load = [{
        key: "title",
        label: _("lbl_time"),
        sortable: true,
    }, {
        key: "value",
        label: _("lbl_value"),
        sortable: true,
    }];
    
    this.tableload = new Yaffas.Table({
        container: "table-load",
        url: "/about/load.cgi",
        "columns": columns_load
    });
    
	var columns_mem = [{
        key: "type",
        label: _("lbl_mem_type"),
        sortable: true,
    }, {
        key: "value",
        label: _("lbl_value"),
        sortable: true,
		formatter: this.formatMem.bind(this)
    }];
    
    this.tablemem = new Yaffas.Table({
        container: "table-mem",
        url: "/about/memory.cgi",
        "columns": columns_mem
    });
}

About.prototype.confirmation = function(url, args, submit){
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

About.prototype.savedForm = function(url){
    switch (url) {
        case "file.cgi":
            //Yaffas.ui.closeTab();
            //Yaffas.ui.resetTab();
            //this.table.reload();
            break;
    }
}

About.prototype.cleanup = function() {
	this.updater.stop();
}

module = new About();
