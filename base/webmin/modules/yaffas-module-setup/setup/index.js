function Setup(){
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
