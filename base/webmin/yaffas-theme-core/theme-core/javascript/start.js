if (typeof console == 'undefined') {
    var console = {};
    console.log = function(msg) {
        return;
    };
}

Yaffas = function() {
	this.LANG = null;
	this.PRODUCTS = null;
	this.AUTH = null;
}

function init() {
	Yaffas.ui = new Yaffas.UI();
	Yaffas.ui.setup();
	document.body.style.display = "block";
	
	Yaffas.list = new Yaffas.List();
}

YAHOO.util.Event.onDOMReady(init);
