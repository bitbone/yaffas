var Users = function(){
	this.usersmenu = null;
	this.usertable = null;
	this.usersource = null;
}

Users.prototype.showEditUser = function() {
	var s = this.usertable.selectedRows();
	
	if (s.length > 0) {
		Yaffas.ui.openTab('/users/edituser.cgi', {user: s[0][0]});
	}
}

Users.prototype.showEditFiletype = function() {
	var s = this.usertable.selectedRows();
	
	if (s.length > 0) {
		Yaffas.ui.openTab('/users/editfiletype.cgi', {user: s[0][0]});
	}
}

Users.prototype.deleteUser = function() {
	var s = this.usertable.selectedRows();
	
	if (s.length > 0) {
		var c = new Yaffas.Confirm(_("lbl_deluser"), _("lbl_delete_question")+dlg_arg(s[0][1]), function() {
			Yaffas.ui.submitURL('/users/check_deluser.cgi', { uid: s[0][0], login_: s[0][1] }); // login_ needed for removal user from sendas list
		});
		c.show();
	}
}

Users.prototype.convertToZarafaResource = function() {
	var s = this.usertable.selectedRows();
	
	if (s.length > 0) {
		var c = new Yaffas.Confirm(_("lbl_convert_to_zarafa_resource"), _("lbl_convert_to_zarafa_resource_question")+dlg_arg(s[0][1]), function() {
			Yaffas.ui.submitURL('/users/convert.cgi', { user: s[0][0] });
		});
		c.show();
	}
}

Users.prototype.setupMenu = function() {
    var i = [];
	
	if (auth_type() === "local LDAP") {
		i.push({
	        text: _("lbl_changeuser"),
	        onclick: {
	            fn: this.showEditUser.bind(this)
	        },
	    }, {
	        text: _("lbl_deluser"),
	        onclick: {
	            fn: this.deleteUser.bind(this)
	        },
	    }/*, {
			text: _("lbl_convert_to_zarafa_resource"),
			onclick: {
				fn: this.convertToZarafaResource.bind(this)
			}
		}*/);
	}
	else if (auth_type() === "Active Directory") {
	    i.push({
			text: _("lbl_convert_to_zarafa_resource"),
			onclick: {
				fn: this.convertToZarafaResource.bind(this)
			}
		});
	}
	else if (auth_type() === "Active Directory" && Yaffas.PRODUCTS.indexOf("fax") >= 0) {
		i.push({
			text: _("lbl_filetype"),
			onclick: {
				fn: this.showEditFiletype.bind(this)
			}
		})
	}
	
    this.usersmenu = new Yaffas.Menu({ container: "usersmenu", trigger: "data", items: i });
}

Users.prototype.setupTable = function() {
	var myColumnDefs = [
    {
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
    }, {
        key: "zarafa_license",
        label: _("lbl_zarafa_license"),
        sortable: true
    }];
	this.usertable = new Yaffas.Table({
		container: "data",
		columns: myColumnDefs,
		url: "/users/users.cgi",
		sortColumn: 1
	});
}

Users.prototype.setupUI = function(){
	this.setupTable();
	this.setupMenu();
}

Users.prototype.savedForm = function(f, args) {
    var u = args["login_"];
    var e = $("sendas_user_");
	switch(f) {
		case "check_newuser.cgi": {
            if (e !== undefined && u !== undefined) {
                e.insert({top: "<option value='"+u+"'>"+u+"</option>"})
            }
			this.usertable.reload();
			Yaffas.ui.resetTab();
			break;
		}
		case "convert.cgi":
		case "check_deluser.cgi":
            if (e !== undefined && u !== undefined) {
                for (var i = 0; i < e.options.length; ++i) {
                    if (e.options[i].value === u) {
                        e.remove(e.options[i]);
                    }
                }
            }
			this.usertable.reload();
			break;
		case "check_edituser.cgi":
			this.usertable.reload();
			Yaffas.ui.closeTab();
			break;
		case "set_filetype_ads.cgi":
			Yaffas.ui.closeTab();
	}
}

Users.prototype.cleanup = function() {
	this.usersmenu.destroy();
}

module = new Users();
module.setupUI();
