var MailServer = function(){
    this.setupTable();
}

MailServer.prototype.controlService = function(a){
    var r = this.table.selectedRows();
    
    if (r.length > 0) {
        Yaffas.ui.submitURL("/mailsrv/check_feature.cgi", {
            feature: r[0][0],
            action: a
        })
    }
}

MailServer.prototype.setupTable = function(){
    var columns = [{
        key: "name",
        label: _("lbl_feature"),
        sortable: true,
    }, {
        key: "enabled",
        label: _("lbl_status"),
        sortable: true,
        formatter: function(e, record, column, data){
            e.innerHTML = data ? _("lbl_active") : _("lbl_disabled");
        }
    }, {
        key: "started",
        label: _("lbl_service"),
        sortable: true,
        formatter: function(e, record, column, data){
            e.innerHTML = data ? _("lbl_started") : _("lbl_stopped");
        }
    }];
    this.table = new Yaffas.Table({
        container: "table",
        url: "/mailsrv/security_features.cgi",
        "columns": columns
    });
    
    var menuitems = [{
        text: _("lbl_start"),
        onclick: {
            fn: this.controlService.bind(this, "start")
        }
    }, {
        text: _("lbl_stop"),
        onclick: {
            fn: this.controlService.bind(this, "stop")
        }
    }];
    
    this.menu = new Yaffas.Menu({
        container: "menu",
        trigger: "table",
        items: menuitems
    });
    
}

/**
 * Creates a confirmation dialog for a script specified by url.
 *
 * @param {Object} url
 * @param {Object} elements
 * @param {Object} submit
 */
MailServer.prototype.confirmation = function(url, elements, submit){
    var showdlg = false;
    var q = "";
    var qa = [];
    switch (url) {
        case "check_domains.cgi":
        case "check_relay.cgi":
            if (elements["del"]) {
                showdlg = true;
            }
            break;
    }
    if (showdlg) {
        var dlg = new Yaffas.Confirm(_("lbl_del"), _("lbl_del_question"), submit);
        dlg.show();
        return true;
    }
    return false;
}

MailServer.prototype.savedForm = function(url, args){
    switch (url) {
        case "check_relay.cgi":
            if (args.ipaddr) {
                Yaffas.list.add("del", args.ipaddr, "/mailsrv/" + url);
                Yaffas.ui.resetTab();
            }
        case "check_domains.cgi":
            if (args.domain) {
                Yaffas.list.add("del", args.domain, "/mailsrv/" + url);
                Yaffas.ui.resetTab();
            }
            if (args.del) {
                Yaffas.list.remove("del", args.del);
            }
            break;
            
        case "check_feature.cgi":
            this.table.reload();
            break;
        default:
            Yaffas.ui.reloadTabs();
    }
}

MailServer.prototype.cleanup = function(){
    this.menu.destroy();
    this.menu = null;
}

function toggle_mailadmin() {
	var e = Yaffas.ui.tabs.get("tabs")[0].get("contentEl").select("[class='mailadmin']");
	
	var activate = false;
	
	if ($("verify_action").value === "mailadmin") {
		activate = true;
	}
	
	for (var i = 0; i < e.length; ++i) {
		e[i].style.display = activate ? "table-cell": "none";
	}
}

module = new MailServer();
