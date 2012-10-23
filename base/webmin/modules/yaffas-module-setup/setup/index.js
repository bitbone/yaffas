function Setup(){
	this.executer = null;
    this.pages = 5;
    this.currentPage = 1;
    this.form = null;

    this.setupUI();
}

Setup.prototype.setupUI = function() {
    this.btnNext = new YAHOO.widget.Button("nextPage");
    this.btnNext.on("click", function(){ this.nextPage() }.bind(this));

    this.btnPrev = new YAHOO.widget.Button("prevPage");
    this.btnPrev.on("click", function(){ this.prevPage() }.bind(this));
    this.btnPrev.set("disabled", true);

    this.btnSubmit = new YAHOO.widget.Button("submit");
    this.btnSubmit.on("click", function(){
        this.submit();
    }.bind(this));
    this.btnSubmit.set("disabled", true);

    this.form = this.btnSubmit.get("element").parentNode.parentNode;
}

Setup.prototype.finished = function() {
    var dlg = new YAHOO.widget.SimpleDialog("logoutdlg", {
        effect: {
            effect: YAHOO.widget.ContainerEffect.FADE,
            duration: 0.25
        },
        fixedcenter: true,
        modal: true,
        visible: false,
        draggable: false,
        zIndex: 30,
        width: "400px",
        close: false
    });

    dlg.setHeader(_("lbl_setup_finished"));
    dlg.setBody(_("lbl_setup_finished_msg"));
    dlg.cfg.setProperty("icon", YAHOO.widget.SimpleDialog.ICON_ALARM);

    var handleYes = function(){
        Yaffas.ui.logout();
    }

    var myButtons = [{
        text: "OK",
        handler: handleYes
    }];

    dlg.cfg.queueProperty("buttons", myButtons);
    dlg.render(document.body);
    dlg.show();
}

Setup.prototype.submit = function() {
    var args = Form.serializeElements(this.form.getElements(), { hash: true });
    Yaffas.ui.submitURL("/setup/initialsetup.cgi", args);
    this.startLogRefresh();
}

Setup.prototype.startLogRefresh = function() {
	if (!this.executer) {
		this.executer = new PeriodicalExecuter(this.refreshLog.bind(this), 2)
	}
}

Setup.prototype.stopLogRefresh = function() {
	if (this.executer) {
		this.executer.stop();
		delete this.executer;
	}
	Yaffas.ui.reloadGlobals();
}

Setup.prototype.refreshLog = function() {
	var callback = {
		success : function(o) {
			var log = YAHOO.util.Dom.get("loadingtext");
			var obj = YAHOO.lang.JSON.parse(o.responseText);
			if (log) {
				if (typeof obj.log !== "undefined") {
					log.innerHTML = "<p>" + _("lbl_some_time") + " ...<br/>" + obj.log + "</p>";
				}
			}
			if (typeof obj.status !== "undefined") {
				if (obj.status === 0) {
					this.stopLogRefresh();
				}
			}
		},
		scope : this
	}
	YAHOO.util.Connect.asyncRequest("POST", "/setup/setuplog.cgi", callback);
}


Setup.prototype.showPage = function(page) {
    if (page <= 0)
        page = 1;
    if (page > this.pages)
        page = this.pages;

    for (var i = 1; i <= this.pages; ++i) {
        var e = $("page-"+i);
        if (e !== null) {
            e.style.display = "none";
        }
    }
    $("page-"+page).style.display = "block";

    this.btnSubmit.set("disabled", true)
    if (page == 1) {
        this.btnPrev.set("disabled", true);
        this.btnNext.set("disabled", false);
    }
    else if (page == this.pages) {
        this.btnPrev.set("disabled", false);
        this.btnNext.set("disabled", true);
        this.btnSubmit.set("disabled", false)
    }
    else {
        this.btnPrev.set("disabled", false);
        this.btnNext.set("disabled", false);
    }

    this.currentPage = page;
}

Setup.prototype.nextPage = function() {
    this.showPage(this.currentPage+1);
}

Setup.prototype.prevPage = function() {
    this.showPage(this.currentPage-1);
}

Setup.prototype.confirmation = function(url, args, submit){
}

Setup.prototype.savedForm = function(url){
    switch (url) {
        case "initialsetup.cgi":
            this.finished();
            break;
    }
}

Setup.prototype.cleanup = function() {
}

module = new Setup();
