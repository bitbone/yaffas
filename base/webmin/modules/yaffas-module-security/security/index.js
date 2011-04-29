Security = function(){
	this.dnsbl = null;
	this.rhsbl = null;
	this.sa_trusted = null;
	this.whitelist = null;
	this.dnsbl_menu = null;
	this.rhsbl_menu = null;
	this.whitelist_menu = null;
	this.sa_trusted_menu = null;

	this.fillTables();
	this.fillDialogs();
	this.setupButtons();

	this.status_policy = $('s_policy').value;
	this.status_spam = $('s_spam').value;
	this.status_antivirus = $('s_antivirus').value;
}

Security.prototype.savedForm = function(url) {
	switch(url) {
		case "dnsbl_add.cgi":
			this.dnsbl.reload();
			$("dnsbl_host").value = '';
			$("dnsbl_hit").value = '';
			$("dnsbl_miss").value = '';
			$("dnsbl_log").value = '';
			break;

		case "dnsbl_delete.cgi":
			this.dnsbl.reload();
			break;

		case "rhsbl_add.cgi":
			this.rhsbl.reload();
			$("rhsbl_host").value = '';
			$("rhsbl_hit").value = '';
			$("rhsbl_miss").value = '';
			$("rhsbl_log").value = '';
			break;

		case "rhsbl_delete.cgi":
			this.rhsbl.reload();
			break;

		case "sa_trusted_add.cgi":
			this.sa_trusted.reload();
			$("sa_trusted_net").value = '';
			break;

		case "sa_trusted_delete.cgi":
			this.sa_trusted.reload();
			break;

		case "whitelist_add.cgi":
			this.whitelist.reload();
			$("whitelist_entry").value = '';
			break;

		case "whitelist_delete.cgi":
			this.whitelist.reload();
			break;

		default:
			Yaffas.ui.reloadTabs();
			break
	}
}

Security.prototype.setupButtons = function() {
	var sa_update = new YAHOO.widget.Button("sa_update");
	sa_update.on("click", function() { 
		Yaffas.ui.submitURL('/security/sa_update.cgi', {});
	}.bind(this)); 

	var spam_submit = new YAHOO.widget.Button("spam_submit");
	spam_submit.on("click", function(){ 
		Yaffas.ui.submitURL('/security/spam_settings.cgi', {headers: $("spam_headers").value});
	}.bind(this));

	var av_submit = new YAHOO.widget.Button("av_submit");
	av_submit.on("click", function() {
		Yaffas.ui.submitURL('/security/clam_settings.cgi', {
            "archive": $("archive").checked,
            "max_length":$("max_length").value,
            "virusalert": $("virusalert").value
            });
	}.bind(this));

	/*
	var av_update = new YAHOO.widget.Button("av_update");
	av_update.on("click", function() {
		Yaffas.ui.submitURL('/security/clam_update.cgi', {});
	}.bind(this));
	*/

	var status_policy = new YAHOO.widget.Button("status_policy");
	status_policy.on("click", function(){
			var d = new Yaffas.Confirm(
				((this.status_policy == 0) ? _("lbl_activate") : _("lbl_deactivate")), 
				((this.status_policy == 0) ? _("lbl_really_enable") : _("lbl_really_disable")), function(){
					var s = null;
					if(this.status_policy == 0)
						s = 1;
					if(this.status_policy == 1)
						s = 0;
					Yaffas.ui.submitURL("/security/set_status.cgi", {"service": "policy", "status": s});
				}.bind(this));
			d.show();
	}.bind(this));

	var status_spam = new YAHOO.widget.Button("status_spam");
	status_spam.on("click", function(){
			var d = new Yaffas.Confirm(
				((this.status_spam == 0) ? _("lbl_activate") : _("lbl_deactivate")), 
				((this.status_spam == 0) ? _("lbl_really_enable") : _("lbl_really_disable")), function(){
					var s = null;
					if(this.status_spam == 0)
						s = 1;
					if(this.status_spam == 1)
						s = 0;
					Yaffas.ui.submitURL("/security/set_status.cgi", {"service": "spam", "status": s});
				}.bind(this));
			d.show();
	}.bind(this));

	var status_antivirus = new YAHOO.widget.Button("status_antivirus");
	status_antivirus.on("click", function(){
			var d = new Yaffas.Confirm(
				((this.status_antivirus == 0) ? _("lbl_activate") : _("lbl_deactivate")), 
				((this.status_antivirus == 0) ? _("lbl_really_enable") : _("lbl_really_disable")), function(){
					var s = null;
					if(this.status_antivirus == 0)
						s = 1;
					if(this.status_antivirus == 1)
						s = 0;
					Yaffas.ui.submitURL("/security/set_status.cgi", {"service": "antivirus", "status": s});
				}.bind(this));
			d.show();
	}.bind(this));

}

Security.prototype.fillDialogs = function() {
	this.dnsbl_dialog = new YAHOO.widget.Dialog("dnsbl_dialog", {
		visible: false,
		fixedcenter: true,
		modal: false,
		zIndex: 100,
		buttons: [
			{text:_("lbl_ok"), handler: function(){ 
				Yaffas.ui.submitURL("/security/dnsbl_add.cgi", {
					'dnsbl_host': $("dnsbl_host").value,
					'dnsbl_hit': $("dnsbl_hit").value,
					'dnsbl_miss': $("dnsbl_miss").value,
					'dnsbl_log': $("dnsbl_log").value
				});
				this.hide();
			}},
			{text:_("lbl_cancel"), handler: function(){ this.cancel(); }}
		]
	});
	this.dnsbl_dialog.render();

	var dnsbladd = new YAHOO.widget.Button("dnsbl_add");
	dnsbladd.on("click", function() { 
		this.dnsbl_dialog.show();
	}.bind(this)); 


	this.rhsbl_dialog = new YAHOO.widget.Dialog("rhsbl_dialog", {
		visible: false,
		fixedcenter: true,
		modal: false,
		zIndex: 100,
		buttons: [
			{text:_("lbl_ok"), handler: function(){ 
				Yaffas.ui.submitURL("/security/rhsbl_add.cgi", {
					'rhsbl_host': $("rhsbl_host").value,
					'rhsbl_hit': $("rhsbl_hit").value,
					'rhsbl_miss': $("rhsbl_miss").value,
					'rhsbl_log': $("rhsbl_log").value
				});
				this.hide();
			}},
			{text:_("lbl_cancel"), handler: function(){ this.cancel(); }}
		]
	});
	this.rhsbl_dialog.render();

	var rhsbladd = new YAHOO.widget.Button("rhsbl_add");
	rhsbladd.on("click", function() { 
		this.rhsbl_dialog.show();
	}.bind(this));


	this.sa_trusted_dialog = new YAHOO.widget.Dialog("sa_trusted_dialog", {
		visible: false,
		fixedcenter: false,
		modal: false,
		buttons: [
			{text:_("lbl_ok"), handler: function(){ 
				Yaffas.ui.submitURL("/security/sa_trusted_add.cgi", {
					'sa_trusted_net': $("sa_trusted_net").value
				});
				this.hide();
			}},
			{text:_("lbl_cancel"), handler: function(){ this.cancel(); }}
		]
	});
	this.sa_trusted_dialog.render();
	this.sa_trusted_dialog.hide();

	var sa_trusted_add = new YAHOO.widget.Button("sa_trusted_add");
	sa_trusted_add.on("click", function(){ this.sa_trusted_dialog.center(); this.sa_trusted_dialog.show(); }.bind(this));


	this.whitelist_dialog = new YAHOO.widget.Dialog("whitelist_dialog", {
		visible: false,
		fixedcenter: false,
		modal: false,
		buttons: [
			{text:_("lbl_ok"), handler: function(){ 
				Yaffas.ui.submitURL("/security/whitelist_add.cgi", {
					'whitelist_entry': $("whitelist_entry").value
				});
				this.hide();
			}},
			{text:_("lbl_cancel"), handler: function(){ this.cancel(); }}
		]
	});
	this.whitelist_dialog.render();
	this.whitelist_dialog.hide();
	
	var whitelist_add = new YAHOO.widget.Button("whitelist_add");
	whitelist_add.on("click", function(){ this.whitelist_dialog.center(); this.whitelist_dialog.show(); }.bind(this));
}

Security.prototype.fillTables = function() {
	var dnsCols = [
	{
		key: "host",
		label: _("lbl_host"),
		sortable: true
	}, {
		key: "hit",
		label: _("lbl_hit"),
		sortable: true
	}, {
		key: "miss",
		label: _("lbl_miss"),
		sortable: true
	}, {
		key: "log",
		label: _("lbl_log"),
		sortable: true
	} ];

	this.dnsbl = new Yaffas.Table({
		container: "dnsbl",
		columns: dnsCols,
		url: "/security/dnsbl.cgi",
		sortColumn: 1,
		sortOrder: YAHOO.widget.DataTable.CLASS_DESC
	});

	this.dnsbl_menu = new Yaffas.Menu({
		container: "dnsbl_menu",
		trigger: "dnsbl",
		items: [
			{text:_("lbl_delete"), onclick: {fn: function() {
				var r = this.dnsbl.selectedRows();

                if (r[0][0]) {
                    var dlg = new Yaffas.Confirm(_("lbl_really_delete"), _("lbl_really_delete_msg"), function() {
                        Yaffas.ui.submitURL("/security/dnsbl_delete.cgi", {
                            host: r[0][0],
                            hit: r[0][1],
                            miss: r[0][2],
                            log: r[0][3]
                        });
                    });
                    dlg.show();
                }
			}.bind(this) } },
		],
	});

	this.rhsbl = new Yaffas.Table({
		container: "rhsbl",
		columns: dnsCols,
		url: "/security/rhsbl.cgi",
		sortColumn: 1,
		sortOrder: YAHOO.widget.DataTable.CLASS_DESC
	});

	this.rhsbl_menu = new Yaffas.Menu({
		container: "rhsbl_menu",
		trigger: "rhsbl",
		items: [
			{text:_("lbl_delete"), onclick: {fn: function() {
				var r = this.rhsbl.selectedRows();

                if (r[0][0]) {
                    var dlg = new Yaffas.Confirm(_("lbl_really_delete"), _("lbl_really_delete_msg"), function() {
                        Yaffas.ui.submitURL("/security/rhsbl_delete.cgi", {
                            host: r[0][0],
                            hit: r[0][1],
                            miss: r[0][2],
                            log: r[0][3]
                        });
                    });
                    dlg.show();
                }
			}.bind(this) } },
		],
	});

	this.sa_trusted = new Yaffas.Table({
		container: "sa_trusted",
		columns: [{key:"network", label:_("lbl_network"), sortable:"true"}],
		url: "/security/sa_trusted.cgi",
	});

	this.sa_trusted_menu = new Yaffas.Menu({
		container: "sa_trusted_menu",
		trigger: "sa_trusted",
		items: [
			{text:_("lbl_delete"), onclick: {fn: function() {
				var r = this.sa_trusted.selectedRows();
                if (r[0][0]) {
                    var dlg = new Yaffas.Confirm(_("lbl_really_delete"), _("lbl_really_delete_msg"), function() {
                        Yaffas.ui.submitURL("/security/sa_trusted_delete.cgi", { network: r[0][0] });
                    });
                    dlg.show();
                }
			}.bind(this) } },
		],
	});

	var wlCols = [
	{
		key: "entry",
		label: _("lbl_wl_entry"),
		sortable: true
	},
	{
		key: "type",
		label: _("lbl_wl_type"),
		sortable: true
	},
	{ 
		key: "from",
		label: _("lbl_wl_from"),
		sortable: true
	}];

	this.whitelist = new Yaffas.Table({
		container: "whitelist",
		columns: wlCols,
		url: "/security/whitelist.cgi",
		sortColumn: 0,
		sortOrder: YAHOO.widget.DataTable.CLASS_ASC
	});

	this.whitelist_menu = new Yaffas.Menu({
		container: "whitelist_menu",
		trigger: "whitelist",
		items: [
			{text:_("lbl_delete"), onclick: {fn: function() {
				var r = this.whitelist.selectedRows();

                if (r[0][0]) {
                    var dlg = new Yaffas.Confirm(_("lbl_really_delete"), _("lbl_really_delete_msg"), function() {
                        Yaffas.ui.submitURL("/security/whitelist_delete.cgi", { whitelist_entry: r[0][0] });
                    });
                    dlg.show();
                }

			}.bind(this) } },
		],
	});
}


Security.prototype.cleanup = function() {
	if(this.dnsbl_menu) this.dnsbl_menu.destroy();
	if(this.rhsbl_menu) this.rhsbl_menu.destroy();
	if(this.sa_trusted_menu) this.sa_trusted_menu.destroy();
	if(this.whitelist_menu) this.whitelist_menu.destroy();
}

module = new Security();
