Yaffas.Confirm = function(t, q, s) {
	this.title = t;
	this.question = q;
	this.submit = s;
}

Yaffas.Confirm.prototype.show = function(){
    var mySimpleDialog = new YAHOO.widget.SimpleDialog("confirmationdlg", {
        width: "40em",
        effect: {
            effect: YAHOO.widget.ContainerEffect.FADE,
            duration: 0.25
        },
        fixedcenter: true,
        modal: true,
        visible: false,
        draggable: false,
		close: false
    });
    mySimpleDialog.setHeader(this.title);
    mySimpleDialog.setBody(this.question);
    mySimpleDialog.cfg.setProperty("icon", YAHOO.widget.SimpleDialog.ICON_WARN);
	
    var handleYes = function(e, obj){
        this.hide();
		obj.submit();
    }
    var handleNo = function(){
        this.hide();
    }
	
    var myButtons = [{
        text: _("lbl_yes", "global"),
        handler: {
			fn: handleYes,
			obj: this
		}
    }, {
        text: _("lbl_no", "global"),
        handler: handleNo,
        isDefault: true
    }];
	
    mySimpleDialog.cfg.queueProperty("buttons", myButtons);
    
    mySimpleDialog.render(document.body);
    mySimpleDialog.show();
	return true;
}
