var Users = function(){
	this.usersmenu = null;
	this.usertable = null;
	this.usersource = null;
}

Users.prototype.showEditUser = function() {
	var s = this.usertable.selectedRows();
	
	if (s.length > 0) {
		Yaffas.ui.openTab('/users/edituser.cgi', {user: s[0][0]}, this.setupButtons.bind(this));
	}
}

Users.prototype.showEditFiletype = function() {
	var s = this.usertable.selectedRows();
	
	if (s.length > 0) {
		Yaffas.ui.openTab('/users/editfiletype.cgi', {user: s[0][0]});
	}
}

Users.prototype.showEditVacation = function() {
	var s = this.usertable.selectedRows();
	
	if (s.length > 0) {
		Yaffas.ui.openTab('/users/editvacation.cgi', {user: s[0][0]}, this.setupVacationCallback.bind(this));
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

Users.prototype.setupVacationCallback = function() {
    var tab = Yaffas.ui.getActiveTabEl();

    var elems = Element.select(tab, "input[name=status]");

    function changeStatus(s) {
        var elems = Element.select(tab, "input[name=subject]");
        elems[0].disabled = !s;
        elems = Element.select(tab, "textarea");
        elems[0].disabled = !s;
    }

    for(var i = 0; i < elems.length; ++i) {
        if (elems[i].value == "false") {
            var e = new YAHOO.util.Element(elems[i]);
            e.on("click", changeStatus.curry(false))
        }
        if (elems[i].value == "true") {
            var e = new YAHOO.util.Element(elems[i]);
            e.on("click", changeStatus.curry(true))
        }
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

Users.prototype.getList = function() {
    var tab = Yaffas.ui.getActiveTabEl();
    var e = Element.select(tab, "select[id=email]");
    if (e !== undefined && e.length)
        return e[0];
    else
        return undefined;
}

Users.prototype.addEMail = function(e) {
    var tab = Yaffas.ui.getActiveTabEl();
    var e = Element.select(tab, "input[id=new_email]")[0];

    if (e.value !== undefined) {
        var list = this.getList();

        var option = new Option(e.value, e.value);

        if (list.options.length == 0)
            option.text = e.value+" (default)";

        var def = false;
        for (var i = 0; i < list.options.length; ++i) {
            var o = list.options[o];

            if (option.text.match(/\(default\)$/gi)) {
                def = true;
            }
        }

        if (def === false) {
            this.setDefaultEMail(0);
        }

        var optsLen = list.options.length;
        list.options[optsLen] = option;

        e.value = "";
    }
}

Users.prototype.removeEMail = function() {
    var list = this.getList();
    var option = list.options[list.selectedIndex];

    list.removeChild(option);

    if (option.text.match(/\(default\)$/gi)) {
        this.setDefaultEMail(0);
    }
}

Users.prototype.modifyEMail = function() {
    var list = this.getList();
    var option = list.options[list.selectedIndex];

    var tab = Yaffas.ui.getActiveTabEl();
    var e = Element.select(tab, "input[id=new_email]")[0];
    e.value = option.value;

    list.removeChild(option);
}

Users.prototype.setDefaultEMail = function(idx) {
    var list = this.getList();
    var index = list.selectedIndex;
    if (YAHOO.lang.isNumber(idx))
        index = idx;
    var option = list.options[index];

    if (option !== undefined) {
        for (var i = 0; i < list.options.length; ++i) {
            list.options[i].text = list.options[i].value;
        }

        option.text = option.value+" (default)";
    }
}

Users.prototype.confirmation = function(url, args, submit) {
    if ((url === "check_edituser.cgi" || url === "check_newuser.cgi") && args["email_"] === undefined) {

        var list = this.getList();

        var tab = Yaffas.ui.getActiveTabEl();
        var e = Element.select(tab, "input[id=uid]");
        var uid = e[0].value;

        var def = "";
        var aliases = [];
        for(var i = 0; i < list.options.length; ++i) {
            var o = list.options[i];
            if (o.text.match(/\(default\)/)) {
                def = o.value;
            }
            else {
                aliases.push(o.value);
            }
        }

        var add = {};
        add["email_"+uid] = def;
        if (aliases.length)
            add["alias_"+uid] = aliases.join(",");

        submit(add);
        return true;
    }
    return false;
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
    i.push({
        text: _("lbl_edit_vacation_msg"),
    onclick: {
        fn: this.showEditVacation.bind(this)
    }
    })
	
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
        label: _("lbl_zarafa_store"),
        sortable: true
    }];
	this.usertable = new Yaffas.Table({
		container: "data",
		columns: myColumnDefs,
		url: "/users/users.cgi",
		sortColumn: 1
	});
}

Users.prototype.setupButtons = function() {
    var e = $$("input[name=email_add]");
    var btn = new YAHOO.widget.Button(e[0]);
    btn.setStyle("vertical-align", "middle");
    btn.on("click", this.addEMail.bind(this));

    e = $$("input[name=email_remove]");
    btn = new YAHOO.widget.Button(e[0]);
    btn.on("click", this.removeEMail.bind(this));

    e = $$("input[name=email_default]");
    btn = new YAHOO.widget.Button(e[0]);
    btn.on("click", this.setDefaultEMail.bind(this));

    e = $$("input[name=email_modify]");
    btn = new YAHOO.widget.Button(e[0]);
    btn.on("click", this.modifyEMail.bind(this));

    /*
    var tab = Yaffas.ui.getActiveTabEl();
    e = Element.select(tab, "input[id=new_email]")[0];
    var kl = new YAHOO.util.KeyListener(e, {
        keys: YAHOO.util.KeyListener.KEY.ENTER
    }, {
        fn: function() {
            // don't commit form on enter key press
            YAHOO.util.Event.preventDefault(e);

            this.addEMail.bind(this);
        }
    });
    kl.enable();

    var l = YAHOO.util.Event.getListeners(tab);
    YAHOO.util.Event.removeListener(tab, "submit");
    tab = new YAHOO.util.Element(tab);
    tab.on("submit", function(ev) {
        //YAHOO.util.Event.preventDefault(ev);
        ev.preventDefault();
        alert("foo");
        l[0].fn();
    }.bind(this));
    */
}

Users.prototype.setupUI = function(){
	this.setupTable();
	this.setupMenu();
	this.setupButtons();
}

Users.prototype.savedForm = function(f, args) {
    var u = args["login_"];
    var e = $("sendas_user_");
	switch(f) {
		case "check_newuser.cgi": {
            if (e !== undefined && u !== undefined) {
                e.insert({top: "<option value='"+u+"'>"+u+"</option>"})
            }
            this.getList().options.length = 0;
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
		case "editvacation.cgi":
		case "set_filetype_ads.cgi":
			Yaffas.ui.closeTab();
            break;
	}
}

Users.prototype.cleanup = function() {
	this.usersmenu.destroy();
}

module = new Users();
module.setupUI();
