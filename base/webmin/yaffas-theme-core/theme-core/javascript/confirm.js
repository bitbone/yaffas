Yaffas.Confirm = function(t, q, s) {
	this.title = t;
	this.question = q;
	this.submit = s;
}

Yaffas.Confirm.prototype.show = function(){
	var id = "confirmationdlg";
	var mySimpleDialog = new YAHOO.widget.SimpleDialog(id, {
		width: "40em",
		effect: {
			effect: YAHOO.widget.ContainerEffect.FADE,
			duration: 0.25
		},
		fixedcenter: true,
		modal: true,
		visible: false,
		draggable: false,
		close: false,
	});
	mySimpleDialog.setHeader(this.title);
	mySimpleDialog.setBody(this.question);
	YAHOO.util.Dom.setStyle(mySimpleDialog.body, "overflow", "auto");
	mySimpleDialog.cfg.setProperty("icon",
		YAHOO.widget.SimpleDialog.ICON_WARN);

	var refit_dialog = function() {
		var maxheight = window.innerHeight - 100;
		if (maxheight < 25) {
			maxheight = 25;
		}
		YAHOO.util.Dom.setStyle(mySimpleDialog.body, "max-height",
			maxheight + "px");
	};
	refit_dialog();
	var resizeTimer;
	var delayed_refit_dialog = function() {
		window.clearTimeout(resizeTimer);
		resizeTimer = window.setTimeout(refit_dialog, 50);
	}
	YAHOO.util.Event.addListener(window, "resize", delayed_refit_dialog);

	var handleYes = function(e, obj) {
		this.hide();
		window.clearTimeout(resizeTimer);
		YAHOO.util.Event.removeListener(window, "resize", delayed_refit_dialog);
		obj.submit();
	};
	var handleNo = function() {
		window.clearTimeout(resizeTimer);
		YAHOO.util.Event.removeListener(window, "resize", delayed_refit_dialog);
		this.hide();
	};

	var myButtons = [
		{
			text: _("lbl_yes", "global"),
			handler: {
				fn: handleYes,
				obj: this
			}
		},
		{
			text: _("lbl_no", "global"),
			handler: handleNo,
			isDefault: true
		}
	];

	mySimpleDialog.cfg.queueProperty("buttons", myButtons);

	mySimpleDialog.render(document.body);
	mySimpleDialog.show();
	return true;
}
