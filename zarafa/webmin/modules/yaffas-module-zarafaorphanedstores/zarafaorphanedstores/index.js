function OrphanedStores(){
	this.table = null;
	this.usertable= null;
	this.menu = null;
	this.hookDialog = null;
	this.setupTable();
}

OrphanedStores.prototype.hookOrphanedStore = function(){
	var r = this.table.selectedRows();
	
	if (r.length > 0) {
		if(this.hookDialog != null) {
			this.hookDialog.show();
		} else {
			hookDialog = new YAHOO.widget.Dialog("hookToUser",
			{
				fixedcenter: true,
				draggable: true,
				close: false,
				width: "750px",
			});
			var onSuccess = function(o) {
				var resMatch = o.responseText.search("/>:-\\(</");
				if(resMatch != -1) {
					alert(_("err_could_not_hook_to_user"));
				}
				module.usertable.destroy();
				module.table.reload();
			};
			var onFailure = function(o) {
				alert("Your submission failed. Status: " + o.status);
			};
			hookDialog.callback.success = onSuccess;
			hookDialog.callback.failure = onFailure;
			var handleSubmit = function() {
				var ur = module.usertable.selectedRows();
				if(ur[0] == undefined) {
					alert(_("err_select_user"));
				} else {
					var postdata = "orphan=" + r[0][0] + "&username=" + ur[0][1];
					hookDialog.cfg.setProperty("postdata", postdata);
					this.submit();
				}
			};
			var handleCancel = function() { this.cancel(); };
			var myButtons = [ { text: _("lbl_submit_hook"), handler:handleSubmit }, { text: _("lbl_cancel_hook"), handler:handleCancel, isDefault:true }];
			hookDialog.cfg.queueProperty("buttons", myButtons);
			hookDialog.setBody('<div id="hookDialog_body"><form method="post" action="/zarafaorphanedstores/hook.cgi" name="hook_orphan"><div id="userdata" /></form></div>');
			hookDialog.setHeader(_("lbl_hook_orphan") + " " + r[0][0]);
			hookDialog.render();
			if(this.usertable == null) {
				this.setupUserTable();
				this.usertable.hideEvent.subscribe(function(o) {
        	       setTimeout(function() {this.usertable.destroy();}, 0);
            	});
			} else {
				this.usertable.setupTable();
			}

			hookDialog.show();
		}
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

OrphanedStores.prototype.setupUserTable = function(){
	var myColumnDefs = [{
			key: "id",
			label: "ID",
			sortable: true,
		hidden: true
	}, {
		key: "username",
		label: _("lbl_userlogin"),
		sortable: true
	}, {
		key: "gecos",
		label: _("lbl_gecos"),
		sortable: true,
	}];

	this.usertable = new Yaffas.Table({
		container: "userdata",
		columns: myColumnDefs,
		url: "/zarafaorphanedstores/users.cgi",
		sortColumn: 1
	});
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
		text: _("lbl_hookorphaned"),
		onclick: {
			fn: this.hookOrphanedStore.bind(this)
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
		case "hook.cgi":
//			Yaffas.ui.closeTab();
			this.table.reload();
			break;
	}
}


OrphanedStores.prototype.cleanup = function(){
	this.menu.destroy();
	this.menu = null;
}

module = new OrphanedStores();

