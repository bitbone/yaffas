Service = function(){
    this.table = null;
    this.menu = null;
    
    this.setupTable();
	this.setupButtons();
}

Service.prototype.startService = function() {
	var r = this.table.selectedRows()
	
	if (r.length > 0) {
		this.control(r[0][0], "start");
	}
}
Service.prototype.restartService = function() {
	var r = this.table.selectedRows()
	
	if (r.length > 0) {
		this.control(r[0][0], "restart");
	}
}
Service.prototype.stopService = function(){
    var r = this.table.selectedRows()
    
    if (r.length > 0) {
        var d = new Yaffas.Confirm(_("lbl_really_stop_title"), _("lbl_really_stop"), function(){
			Yaffas.ui.submitURL("/service/control.cgi", {"service": r[0][0], "action": "stop"})
        }.bind(this));
		d.show();
    }
}

Service.prototype.control = function(service, action) {
	Yaffas.ui.submitURL("/service/control.cgi", {"service": service, "action": action})
}

YAHOO.widget.DataTable.Formatter["startOnBootColumn"] = function(e, record, column, data){
	var disabled = "";
	
	switch(record.getData().name) {
		case "network":
		case "yaffas":
			disabled = "disabled";
	}
	
	e.innerHTML = "<input type='checkbox' "+disabled+" "+((data === 1) ? "checked" : "")+" />";
	
	YAHOO.util.Event.addListener(e.getElementsByTagName("input")[0], "click", function() {
		console.log("clicked %s %s", this.checked, record.getData().name);
		Yaffas.ui.submitURL("/service/startonboot.cgi", {service: record.getData().name, value: this.checked ? "1" : "0"})
	});}

YAHOO.widget.DataTable.Formatter["statusColumn"] = function(e, record, column, data) {
	if (data === 0) {
		e.innerHTML = _("lbl_stopped")
		YAHOO.util.Dom.addClass(e, 'red');
	}
	else {
		e.innerHTML = _("lbl_started") 
		YAHOO.util.Dom.addClass(e, 'green');
	}
}

Service.prototype.setupTable = function(){
    var menuitems = [{
        text: _("lbl_start"),
        onclick: {
            fn: this.startService.bind(this)
        }
    }, {
        text: _("lbl_restart"),
        onclick: {
            fn: this.restartService.bind(this)
        }
    }, {
        text: _("lbl_stop"),
        onclick: {
            fn: this.stopService.bind(this)
        }
    }];
    
    var columns = [{
        key: "name",
        label: _("lbl_service"),
        sortable: true
    }, {
        key: "status",
        label: _("lbl_status"),
        sortable: true,
		formatter: "statusColumn"
    }, {
        key: "startonboot",
        label: _("lbl_service_on_boot"),
        sortable: true,
		formatter: "startOnBootColumn"
    }];
    
    this.table = new Yaffas.Table({
        container: "table",
        columns: columns,
        url: "/service/services.cgi",
        sortColumn: 1
    });
    
    this.menu = new Yaffas.Menu({
        container: "menu",
        trigger: "table",
        items: menuitems
    });
}

Service.prototype.confirmSystemStatus = function(s) {
	
	var dialog = new YAHOO.widget.SimpleDialog("shutdown_dialog",
	{
		fixedcenter: true,
		modal: true
	});
	
	var btn = [{
		text: _("lbl_ok"), handler: function() {Yaffas.ui.logout()}
	}];
	
	dialog.setHeader(_("lbl_"+s));
	dialog.setBody(_("lbl_"+s+"ing"));
	dialog.cfg.queueProperty("buttons", btn);
	
	var d = new Yaffas.Confirm(_("lbl_"+s), _("lbl_sure_"+s), function() {
		Yaffas.ui.submitURL("/service/shutdown.cgi", {"mode": s});
		dialog.render(document.body);
		dialog.show();
	});
	d.show();
}

Service.prototype.setupButtons = function() {
	var shutdown = new YAHOO.widget.Button("halt");
	shutdown.on("click", this.confirmSystemStatus.bind(this, "halt"));

	var reboot = new YAHOO.widget.Button("reboot");
	reboot.on("click", this.confirmSystemStatus.bind(this, "reboot"));
}

Service.prototype.savedForm = function(url) {
	switch(url) {
		case "control.cgi":
			this.table.reload();
			break;
		case "set_datetime.cgi":
		case "set_timeserver.cgi":
			Yaffas.ui.reloadTabs();
			break;
	}
}

Service.prototype.cleanup = function() {
	this.menu.destroy();
}

module = new Service();
