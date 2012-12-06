Groups = function() {
	this.table = null;
	this.menu = null;
	this.setupTable();
	if (Yaffas.MODULES.indexOf("maildisclaimers") >= 0) {
		YAHOO.util.Get.script("/maildisclaimers/lib.js");
	}
}

Groups.prototype.editGroup = function() {
	var r = this.table.selectedRows();
	
	if (r.length > 0) {
		Yaffas.ui.openTab("/group/edit_groups.cgi", {groups: r[0][0], showform: 1})
	}
}
Groups.prototype.deleteGroup = function() {
	var r = this.table.selectedRows();
	
	if (r.length > 0) {
		var d = new Yaffas.Confirm(_("lbl_delete"), _("lbl_ask_delete")+dlg_arg(r[0][0]), function() {
			Yaffas.ui.submitURL("/group/rm_groups.cgi", {groups: r[0][0]})
		});
		d.show();
	}
}
Groups.prototype.showEditDisclaimer = function() {
	var r = this.table.selectedRows();

	if (r.length > 0) {
		Yaffas.ui.openTab('/maildisclaimers/setgroup.cgi', {groups: r[0][0]},
			MailDisclaimers.setupDisclaimerCallback);
	}
}


Groups.prototype.setupTable = function() {
	var menuitems = [];

	if (auth_type() === "local LDAP") {
		menuitems.push({
			text: _("lbl_edit"),
			onclick: {
				fn: this.editGroup.bind(this)
			}
		}
		);

		menuitems.push({
			text: _("lbl_delete"),
			onclick: {
				fn: this.deleteGroup.bind(this)
			}
		});
	}

	if (Yaffas.MODULES.indexOf("maildisclaimers") >= 0) {
		menuitems.push({
			text: _("lbl_edit_disclaimer"),
			onclick: {
				fn: this.showEditDisclaimer.bind(this)
			}
		});
	}

	var columns = [
	{
		key: "group",
		label: _("lbl_groupname"),
		sortable: true
	}, {
		key: "users",
		label: _("lbl_user"),
		sortable: true,
	}];
		
	this.table = new Yaffas.Table({
		container: "table",
		columns: columns,
		url: "/group/groups.cgi",
		sortColumn: 0
	});

	this.menu = new Yaffas.Menu({container: "menu", trigger: "table", items: menuitems});
}

Groups.prototype.savedForm = function(url) {
	switch(url) {
		case "add_groups.cgi":
			Yaffas.ui.resetTab();
			this.table.reload();
			break;
		case "edit_groups.cgi":
			Yaffas.ui.closeTab();
			this.table.reload();
			break;
		case "rm_groups.cgi":
			this.table.reload();
			break;
		case "setgroup.cgi": // real url: /maildisclaimers/setgroup.cgi
			Yaffas.ui.closeTab();
			break;
	}
}

Groups.prototype.cleanup = function() {
	if (this.menu) {
		this.menu.destroy();
		this.menu = null;
	}
}

module = new Groups();
