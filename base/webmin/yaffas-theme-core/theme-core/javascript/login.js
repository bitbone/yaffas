Yaffas.Login = function(){
    Yaffas.ui = new Object();
    this.layout = null;
    
    var div = document.getElementById('lang');
    if (div.innerHTML !== undefined) {
        Yaffas.LANG = YAHOO.lang.JSON.parse(div.innerHTML);
        div.innerHTML = "";
    }
    Yaffas.ui.currentPage = "global";
    
    
    this.ui = new Yaffas.UI();
    this.ui.initErrorDialog();
    this.ui.initLoadingDialog();
    
    var re = $('response').select('[class="error"]');
    var rw = $('response').select('[class="warning"]');
    
    if (re.length > 0) {
        var e = re[0].parentNode.getElementsByTagName("div");
        this.errorDialog.setBody(e[0].innerHTML);
        this.errorDialog.show();
        
        return true;
    }
    else 
        if (rw.length > 0) {
            var e = rw[0].parentNode.getElementsByTagName("div");
            this.handleReLogin(e[0].innerHTML);
            return true;
        }

		function addkeylistener(field, callback) {
			var kl = new YAHOO.util.KeyListener(field, {
                keys: YAHOO.util.KeyListener.KEY.ENTER
            }, {
                fn: callback
            });
            kl.enable();
		}

        var username = YAHOO.util.Dom.get("user");
        if (username) {
			addkeylistener(username, function() {
						$("password").focus();
			});
        }
        var password = YAHOO.util.Dom.get("password");
        if (password) {
			addkeylistener(password, this.handleLogin.bind(this));
        }
    
}

Yaffas.Login.prototype.setup = function(){
    this.layout = new YAHOO.widget.Layout("mainview", {
        units: [{
            position: "center",
            body: "tabbar",
            scroll: true,
            height: "100%",
        }, {
            position: "top",
            height: "85px",
            body: "topbar"
        }, {
            position: "bottom",
            height: "40px",
            body: "bottombar",
        }]
    });

    this.layout.render();
    this.loginDialog = new YAHOO.widget.Dialog("login", {
        width: "300px",
        fixedcenter: true,
        visible: true,
        constraintoviewport: true,
        close: false,
        hideaftersubmit: false,
        buttons: [{
            text: "Login",
            handler: this.handleLogin.bind(this)
        }]
    });
    var d = this.loginDialog;
    var s = function(){
        $("error_dlg").style.display = "none";
        $("wait").style.display = "none";
        d.render();
        d.show();
        d.center();
        $("error_dlg").style.display = "block";
        $("wait").style.display = "block";
        // IE9 scrolls to bottom, because login dialog is created there - so we now jump to the top
        scrollTo(0);

        YAHOO.util.Event.addListener(window, "resize", function() { Yaffas.login.layout.resize() }.bind(this));
    };
    s.delay(0.1);

}

Yaffas.Login.prototype.handleReLogin = function(msg){
    this.ui.loading.hide();
    var dlg = new Yaffas.Confirm("Admin logged in", msg, function(){
        location.replace("/admin.cgi?force=true");
    });
    dlg.show();
}


Yaffas.Login.prototype.handleLogin = function(){
	this.ui.loading.show();
    this.loginDialog.callback.success = function(o){
        var div = document.getElementById('response');
        if (o.responseText !== undefined) {
            div.innerHTML = o.responseText;
            
            var re = $('response').select('[class="error"]');
            var rw = $('response').select('[class="warning"]');
            
            if (re.length > 0) {
	            this.ui.loading.hide();
                this.ui.errorDialog.setBody("<div style='min-width: 180px; text-align: center'>"+re[0].innerHTML+"</div>");
                this.ui.errorDialog.show();
                return true;
            }
            else 
                if (rw.length > 0) {
                    var e = rw[0].parentNode.getElementsByTagName("div");
                    this.handleReLogin(e[0].innerHTML);
                    return true;
                }
                else {
                    // everything went fine, goto index page
                    location.replace("/");
                }
        }
        
    }.bind(this);
    this.loginDialog.callback.failure = function(o){
        if (o.responseText !== undefined) {
            this.ui.errorDialog.setBody(o.responseText);
            this.ui.errorDialog.show();
        }
        
    }.bind(this);
    this.loginDialog.submit();
    
}
