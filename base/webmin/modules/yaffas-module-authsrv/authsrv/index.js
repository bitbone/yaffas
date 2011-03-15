Authsrv = function(){
    this.setupUI();
	this.setupChooseAuthButton();
	this.setupTestDCButton();
}

Authsrv.prototype.confirmation = function(url, args, submit){
    if (url == "check_ads.cgi" && ! args["ldaps"]) {
        var callback = {
            success: function(o) {
				var i = YAHOO.lang.JSON.parse(o.responseText);
                if (typeof (i.ldaps) !== "undefined" && i.ldaps === 0) {
					var dlg = new Yaffas.Confirm(_("lbl_title_woe"), _("lbl_ads_without_enc"), function() {
						args["ldaps"] = 1;
						Yaffas.ui.submitURL("/authsrv/check_ads.cgi", args);
					});
					dlg.show();
				}
				else {
					args["ldaps"] = 1;
					Yaffas.ui.submitURL("/authsrv/check_ads.cgi", args);
				}
            },
            failure: function(e){
            	console.log("failure on get");
            },
            scope: this
        }
        
        YAHOO.util.Connect.asyncRequest("POST", "/authsrv/test_ldaps.cgi", callback, "pdc="+args.pass_pdc);
	    return true;
    }
    if (url == "check_ldap.cgi" && ! args["ldaps"]) {
        var callback = {
            success: function(o) {
				var i = YAHOO.lang.JSON.parse(o.responseText);
                if (typeof (i.ldaps) !== "undefined" && i.ldaps === 0) {
					var dlg = new Yaffas.Confirm(_("lbl_title_woe"), _("lbl_ldap_without_enc"), function() {
						args["ldaps"] = 1;
						Yaffas.ui.submitURL("/authsrv/check_ldap.cgi", args);
					});
					dlg.show();
				}
				else {
					args["ldaps"] = 1;
					Yaffas.ui.submitURL("/authsrv/check_ldap.cgi", args);
				}
            },
            failure: function(e){
            	console.log("failure on get");
            },
            scope: this
        }
        
        YAHOO.util.Connect.asyncRequest("POST", "/authsrv/test_ldaps.cgi", callback, "pdc="+args.host);
	    return true;
    }
}

Authsrv.prototype.setupChooseAuthButton = function() {
	var btn = new YAHOO.widget.Button("chooseauth");
	btn.on("click", function() {
		var a = $("selectauth").value;
		Yaffas.ui.openTab("/authsrv/index.cgi", {auth: a});
	})
}

Authsrv.prototype.setupTestDCButton = function() {
	var b = YAHOO.util.Dom.get("testdc");
	
	if (b) {
		var btn = new YAHOO.widget.Button(b);
		btn.on("click", function() {
			Yaffas.ui.openTab("/authsrv/test_pdc_connection.cgi", {});
		});
	}
}

Authsrv.prototype.showSIDSelect = function(args) {
	//Yaffas.loading.hide();
	this.siddialog = new YAHOO.widget.Dialog("siddialog", {
        visible: true,
        fixedcenter: true,
        modal: false,
		width: "400px",
        zIndex: 100,
        buttons: [{
            text: _("lbl_ok"),
            handler: function(args){
				var sid = $("sambasid").value;
				if (sid) {
					args["sambasid"] = sid;
					Yaffas.ui.submitURL("/authsrv/check_ldap.cgi", args);
					$("response").innerHTML = "";
					this.cancel();
				}
            }.curry(args)
        }, {
            text: _("lbl_cancel"),
            handler: function(){
				this.cancel();
            }
        }]
    });
	this.siddialog.render(document.body);
	this.siddialog.show();
}

Authsrv.prototype.savedForm = function(url, args) {
	var auth = "";

	switch(url) {
		case "check_ads.cgi":
			auth = "Active Directory";
			break;
		case "check_ldap.cgi":
			var s = $("sambasid");
			if (s && typeof args.sambasid === "undefined") {
				this.showSIDSelect(args);
				return;
			}
			auth = "remote LDAP";
			break;
		case "check_local_ldap.cgi":
			auth = "local LDAP";
			break;
		case "check_pdc.cgi":
			auth = "Primary Domain Controller";
			break;
	}
	if (auth) {
		Yaffas.AUTH.current = auth;
	}
	Yaffas.ui.reloadTabs();
}

Authsrv.prototype.setupUI = function(){

}

module = new Authsrv();
