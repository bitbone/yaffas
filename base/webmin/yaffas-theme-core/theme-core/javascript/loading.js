Yaffas.Loading = function(d) {
	this.counter = 0;
	this.dlg = new YAHOO.widget.Panel("wait", {
        width: "240px",
        fixedcenter: true,
        close: false,
        draggable: false,
        modal: true,
        visible: false,
        zIndex: 30
    });
    
    this.dlg.setHeader(_("lbl_loading", "global"));
    this.dlg.setBody('<img src="/images/loading.gif" /><div id="loadingtext"></div>');
    this.dlg.render(document.body);
}

Yaffas.Loading.prototype.show = function() {
	if (this.counter <= 0) {
		this.dlg.show();
	}
	this.counter++;
}

Yaffas.Loading.prototype.hide = function() {
	this.counter--;
	if (this.counter <= 0) {
		this.dlg.hide();
		this.counter = 0;
	}
}
