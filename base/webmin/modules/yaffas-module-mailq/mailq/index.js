Mailq = function() {
	this.table = null;

    this.forwardDialog = new YAHOO.widget.Dialog("forwardform", {
        visible: false,
        fixedcenter: true,
		width: "400px",
		modal: false,
		zIndex: 100,
        buttons: [{
            text: _("lbl_ok"),
            handler: this.forwardMailSubmit.bind(this)
        }, {
            text: _("lbl_cancel"),
            handler: function(){
				this.cancel();
			}
		}
		]
    });
	this.forwardDialog.render();

	this.setupTable();
}

Mailq.prototype.setup = function() {
}

Mailq.prototype.deleteMail = function() {
	var r = this.table.selectedRows();
	
	if (r.length > 0) {
		var c = new Yaffas.Confirm(_("lbl_delete"), _("lbl_really_del")+dlg_arg(r[0][0]), function() {
			Yaffas.ui.submitURL("/mailq/delete.cgi", {
				mailid: r[0][0]
			});
		});
		c.show();
	}
}

Mailq.prototype.dequeueMail = function() {
	var r = this.table.selectedRows();
	
	if (r.length > 0) {
		Yaffas.ui.submitURL("/mailq/dequeue.cgi", {mailid: r[0][0]})
	}
}
Mailq.prototype.forwardMail = function() {
	this.forwardDialog.show();
}

Mailq.prototype.forwardMailSubmit = function() {
	var m = $("email").value;
	var r = this.table.selectedRows();
	

	if (m != "" && r.length > 0) {
		Yaffas.ui.submitURL("/mailq/forward.cgi", {mailid: r[0][0], "mail": m});
		this.forwardDialog.hide();
	}
}

Mailq.prototype.showMail = function() {
	var r = this.table.selectedRows();
	
	if (r.length > 0) {
		Yaffas.ui.openTab("/mailq/showmail.cgi", {mailid: r[0][0]});
	}
	
}

Mailq.prototype.setupTable = function() {

    var menuitems = [{
        text: _("lbl_delete"),
        onclick: {
            fn: this.deleteMail.bind(this)
        }
    },
	{
		text: _("lbl_dequeue"),
		onclick: {
			fn: this.dequeueMail.bind(this)
		}
	},
	{
		text: _("lbl_show"),
		onclick: {
			fn: this.showMail.bind(this)
		}
	}
	];
		
	var columns = [
    {
        key: "id",
        label: "ID",
        sortable: true,
		hidden: true
    }, {
        key: "sender",
        label: _("lbl_sender"),
        sortable: true
    }, {
        key: "receiver",
        label: _("lbl_recipient"),
        sortable: true,
    }, {
        key: "size",
        label: _("lbl_size"),
        sortable: true
    }, {
		key: "time",
		label: _("lbl_time"),
		sortable: true
	}, {
		key: "status",
		label: _("lbl_status"),
		sortable: true
	}
	];
		
	this.table = new Yaffas.Table({
		container: "table",
		columns: columns,
		url: "/mailq/mailq.cgi",
		sortColumn: 1
	});
	
	this.menu = new Yaffas.Menu({container: "menu", trigger: "table", items: menuitems});
}

Mailq.prototype.savedForm = function(url) {
	switch(url) {
		case "forward.cgi":
		case "dequeue.cgi":
		case "delete.cgi":
			this.table.reload();
			break;
	}
}

Mailq.prototype.cleanup = function() {
	this.menu.destroy();
}

module = new Mailq();
