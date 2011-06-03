Yaffas = function() {
}

function init() {
	Yaffas.login = new Yaffas.Login();
	Yaffas.login.setup();
	document.body.style.display = "block";
}

YAHOO.util.Event.onDOMReady(init);