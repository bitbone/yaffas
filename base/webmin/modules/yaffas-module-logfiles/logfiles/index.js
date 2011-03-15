function Logfile(){
    this.setupTable();
}

Logfile.prototype.download = function() {
	var r = this.table.selectedRows();
	if (r.length > 0) {
		window.open("/logfiles/index.cgi?file="+r[0][0]);
		window.close();
	}
}

Logfile.prototype.setupTable = function(){
    var columns = [{
        key: "file",
        label: _("lbl_file"),
        sortable: true,
    }, {
        key: "size",
        label: _("lbl_size"),
        sortable: true,
		formatter: function(e, record, column, data){
			e.innerHTML = data+" kB";
		}
    }];
    
    this.table = new Yaffas.Table({
        container: "table",
        url: "/logfiles/files.cgi",
        "columns": columns
    });
    
    var menuitems = [{
        text: _("lbl_download"),
        onclick: {
            fn: this.download.bind(this)
        },
    }];
    
    this.menu = new Yaffas.Menu({
        container: "menu",
        trigger: "table",
        items: menuitems
    });
    
}

Logfile.prototype.cleanup = function() {
	this.menu.destroy();
	this.menu = null;
}

module = new Logfile();
