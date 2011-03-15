function Fetchmail() {
	this.openedTabs = {};
    this.setupTable();
}

YAHOO.widget.DataTable.Formatter["activeColumn"] = function(e, record, column, data){
	e.innerHTML = data ? _("lbl_yes") : _("lbl_no");
}

Fetchmail.prototype.addUser = function(idx) {
	var template = YAHOO.util.Dom.get("template-"+idx)
	
	if (template) {
		var copy = template.cloneNode(true);
		YAHOO.util.Dom.insertBefore(copy, template);
		var prev = copy.previousSibling.getElementsByTagName("input");
		
		var newid = parseInt(prev[0].name.replace(/^.*_/, "")) + 1;
		var e = copy.getElementsByTagName("input");
		
		for (var i = 0; i < e.length; ++i) {
			e[i].name = e[i].name + newid;
		}
		
		e = copy.getElementsByTagName("select");
		
		for (var i = 0; i < e.length; ++i) {
			e[i].name = e[i].name + newid;
		}
		
		copy.getElementsByTagName("hr")[0].style.display = "block";
		copy.id = "";
		copy.style.display = "block";
		
		$("tabbar").scrollTop = $("tabbar").scrollHeight;
	}
}

Fetchmail.prototype.editPoll = function() {
	var r = this.table.selectedRows();
	
	if (r.length > 0) {
		if (typeof this.openedTabs[r[0][0]] === "undefined") {
			Yaffas.ui.openTab("/fetchmail/edit_poll.cgi", {idx: r[0][0]}, this.setupButtons.bind(this, r[0][0]));
			this.openedTabs[r[0][0]] = 1;
		}
	}
}

Fetchmail.prototype.deletePoll = function() {
	var r = this.table.selectedRows();
	
	if (r.length > 0) {
		var d = new Yaffas.Confirm(_("lbl_delete"), _("lbl_really_delete"), function() {
			Yaffas.ui.submitURL("/fetchmail/save_poll.cgi", {idx: r[0][0], "delete": 1})
		});
		d.show();
	}
}

Fetchmail.prototype.editSettings = function() {
	Yaffas.ui.openTab("/fetchmail/edit_global.cgi");
}

Fetchmail.prototype.setupButtons = function(idx) {
	var e = YAHOO.util.Dom.get("adduser-"+idx);
	if (e) {
		var btn = new YAHOO.widget.Button(e);
		btn.on("click", this.addUser.bind(this, idx));
	}
}

Fetchmail.prototype.setupTable = function(){
    var columns = [{
        key: "index",
        label: "index",
		hidden: true
    }, {
        key: "server",
        label: _("index_poll"),
        sortable: true
    }, {
        key: "active",
        label: _("index_active"),
        sortable: true,
		formatter: "activeColumn"
    }, {
        key: "proto",
        label: _("index_proto"),
        sortable: true,
    }, {
        key: "users",
        label: _("index_users"),
        sortable: false,
    }];
	
	var menuitems = [{
        text: _("poll_edit"),
        onclick: {
            fn: this.editPoll.bind(this)
        }
    }, {
        text: _("lbl_delete"),
        onclick: {
            fn: this.deletePoll.bind(this)
        }
    }];
	
	var menubaritems = [{
		text: _("lbl_settings"),
		onclick: {
			fn: this.editSettings.bind(this)
		}
	}];
    
    this.table = new Yaffas.Table({
        url: "/fetchmail/polls.cgi",
        container: "table",
        "columns": columns,
		sortColumn: 1
    });
	
	this.menu = new Yaffas.Menu({
		trigger: "table",
		items: menuitems,
		container: "menu"
	});
	
    this.menubar = new YAHOO.widget.MenuBar("menubar");
    this.menubar.addItems(menubaritems);
    this.menubar.render();
    this.menubar.show();
}

Fetchmail.prototype.beforeCloseTab = function(index, tab) {
	var t = tab.get("contentEl").select("input[name='idx']");
	if (t.length > 0) {
		var v = t[0].value;

		delete this.openedTabs[v];
	}
}

Fetchmail.prototype.savedForm = function(url, args) {
	switch(url) {
		case "save_poll.cgi":
			var newEntry = args["new"];
			this.table.reload();
			Yaffas.ui.resetTab();
			if (newEntry === "0")
				Yaffas.ui.closeTab();
			break;
		case "save_global.cgi":
			Yaffas.ui.closeTab();
			break;
	}
}

Fetchmail.prototype.cleanup = function() {
	this.menu.destroy();
	this.menu = null;
	this.menubar.destroy();
	this.menubar = null;
}

module = new Fetchmail();
