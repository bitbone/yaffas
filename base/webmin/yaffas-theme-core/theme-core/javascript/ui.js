Yaffas.UI = function() {
	this.categories = {};
	this.categoryCounter = 0;
	this.currentPage = "";
	this.menu = null;
	this.tabs = null;
	this.loading = null;
	this.errorDialog = null;
	this.layout = null;

	this.addCloseButton = false;
	this.showHelpTooltip = true;
};

Yaffas.UI.prototype.setup = function(){
	this.initLoadingDialog();
	this.initErrorDialog();
	this.initHistoryManager();
	this.createNavigationMenu();
	this.createTabBar();
	this.createMenuBar();

	this.layout = new YAHOO.widget.Layout("mainview", {
		units: [
			{
				position: "left",
				width: 205,
				height: "100%",
				body: "navigation",
				resize: false,
				scroll: false
			}, {
				position: "center",
				body: "tabbar",
				scroll: true,
				width: "100%",
			}, {
				position: "top",
				height: "85px",
				body: "topbar",
				scroll: null /* default is false, which leads to overflow:hidden! */
			}, {
				position: "bottom",
				height: "40px",
				body: "bottombar",
			}
		]
	});

	this.layout.render();
	YAHOO.util.Event.addListener(window, "resize", function() {
		this.layout.resize()
	}.bind(this));
};

Yaffas.UI.prototype.createNavigationMenu = function() {
	this.menu = new YAHOO.widget.AccordionView('navigation', {
		collapsible: true,
		expandable: false,
		hoverActivated: false,
		width: "200px",
		expandItem: 0,
		hoverTimeout: 600,
		animate: false,
		animationSpeed: '0.5'
	});
};

Yaffas.UI.prototype.createTabBar = function() {
	this.tabs = new YAHOO.widget.TabView();
	this.tabs.appendTo("tabbar");
	YAHOO.util.Dom.addClass(this.tabs, "hidden");
	this.tabs.addListener("beforeActiveIndexChange", function() {
		$$(".tooltip div:not(.hidden)").each(function(a) {
			a.addClassName("hidden")
		});
	});
};

Yaffas.UI.prototype.createMenuBar = function() {
	var items = [];

	if (location.port === "10000") {
		items.push({
			text: _("lbl_about_"+Yaffas.CONFIG.theme, "global"),
			onclick: {
				fn: this.openAbout.bind(this)
			},
			id: "about"
		});
	}

	items.push({
		text: _("lbl_help", "global"),
		onclick: {
			fn: this.openHelp.bind(this)
		},
		id: "help"
	}, {
		text: _("lbl_lang", "global"),
		id: "main_language",
		submenu: {
			id: "language",
			itemdata: [
				{
					text: _("lbl_lang_de", "global"),
					onclick: {
						fn: this.setLanguage.bind(this, "de")
					}
				}, {
					text: _("lbl_lang_en", "global"),
					onclick: {
						fn: this.setLanguage.bind(this, "en")
					}
				}
	/*, {
					text: _("lbl_lang_nl", "global"),
					onclick: {
						fn: this.setLanguage.bind(this, "nl")
					}
				}*/, {
					text: _("lbl_lang_fr", "global"),
					onclick: {
						fn: this.setLanguage.bind(this, "fr")
					}
				}, {
					text: _("lbl_lang_pt_BR", "global"),
					onclick: {
						fn: this.setLanguage.bind(this, "pt_BR")
					}
				}, {
					text: _("lbl_lang_zh_TW", "global"),
					onclick: {
						fn: this.setLanguage.bind(this, "zh_TW")
					}
				}
			]
		}
	}, {
		text: _("main_logout", "global"),
		onclick: {
			fn: this.logout.bind(this)
		},
		id: "logout"
	});

	var m = new YAHOO.widget.MenuBar("uimenubar", {
		lazyload: true,
		position: "dynamic",
		visible: true
	});
	m.addItems(items);
	m.render($("topbar"));

	var e = YAHOO.util.Dom.get("main_language");
	if (e) {
		e.style.backgroundImage = "url(/images/flag_"+Yaffas.LANG.used+".png)";
	}

	var onSubmenuShow = function() {
		console.log("show submenu");

		var oIFrame, oElement, nOffsetWidth;
		// Keep the left-most submenu against the left edge of the
		// browser viewport

		if (this.id == "yahoo") {
			YAHOO.util.Dom.setX(this.element, 0);
			oIFrame = this.iframe;            
			if (oIFrame) {
				YAHOO.util.Dom.setX(oIFrame, 0);
			}
			this.cfg.setProperty("x", 0, true);
		}

		/*
		 * Need to set the width for submenus of submenus in IE to prevent
		 * the mouseout event from firing prematurely when the user mouses
		 * off of a MenuItem's text node.
		 */

		if ((this.id == "filemenu" || this.id == "editmenu") && YAHOO.env.ua.ie) {
			oElement = this.element;
			nOffsetWidth = oElement.offsetWidth;

			/*
			 * Measuring the difference of the offsetWidth before and after
			 * setting the "width" style attribute allows us to compute the
			 * about of padding and borders applied to the element, which in
			 * turn allows us to set the "width" property correctly.
			 */
			oElement.style.width = nOffsetWidth + "px";
			oElement.style.width = (nOffsetWidth - (oElement.offsetWidth - nOffsetWidth)) + "px";
		}
	}

	m.subscribe("show", onSubmenuShow);
};

Yaffas.UI.prototype.initHistoryManager = function() {
	// History
	var myModuleBookmarkedState = YAHOO.util.History.getBookmarkedState("m");
	var myModuleInitialState = myModuleBookmarkedState || ""; 

	var myModuleStateChangeHandler = function(state) {
		console.log("state %s", state);
		this.openPageCall(state);
	}

	YAHOO.util.History.register("m", myModuleInitialState,
		myModuleStateChangeHandler.bind(this));
	YAHOO.util.History.initialize("yui-history-field", "yui-history-iframe");

	YAHOO.util.History.onReady(function() {
		var state = YAHOO.util.History.getCurrentState("m");
		if (state) {
			this.openPageCall(state);
		} else {
			if (location.port === "10000") {
				if ($("menuitem-setup")) {
					this.openPageCall("setup");
				} else {
					this.openPageCall("about");
				}
			}
		}
	}.bind(this));
};

Yaffas.UI.prototype.initErrorDialog = function() {
	this.errorDialog = new YAHOO.widget.SimpleDialog("error_dlg", {
		effect: {
			effect: YAHOO.widget.ContainerEffect.FADE,
			duration: 0.25
		},
		fixedcenter: true,
		modal: true,
		visible: false,
		draggable: false,
		zIndex: 30
	});
	this.errorDialog.setHeader(_("lbl_error", "global"));
	this.errorDialog.setBody("");
	this.errorDialog.cfg.setProperty("icon", YAHOO.widget.SimpleDialog.ICON_ALARM);

	var handleYes = function() {
		this.hide();
	}

	var myButtons = [{
		text: "OK",
		handler: handleYes
	}];
	this.errorDialog.cfg.queueProperty("buttons", myButtons);
	this.errorDialog.render(document.body);
};

Yaffas.UI.prototype.initLoadingDialog = function(){
	this.loading = new Yaffas.Loading();
};

Yaffas.UI.prototype.replaceTabs = function(o) {
	while (true) {
		var tab = this.tabs.getTab(0);

		if (tab === undefined) {
			break;
		}
		this.tabs.removeTab(tab);
	}
	if (!this.openTabs(o)) {
		return;
	}

	YAHOO.util.Get.script("/" + this.currentPage + "/index.js", {
		onSuccess: function() {
			console.log("loaded Script")
		}
	});

	this.tabs.selectTab(0);
	this.addCloseButton = true;
	this.replaceValueForm();
	this.loading.hide();
};

Yaffas.UI.prototype.getResponseHTML = function(o) {
	/*
	 * Returns the HTML of the given YUI async response
	 *
	 * We handle two cases here:
	 * - o is the response object
	 * - o.response is the response object
	 *
	 * Also, we try to use .responseXML first, as that's the technical
	 * correct way to get the desired output. As this is not always
	 * populated, we fall back to using .responseText.
	 * We cannot always use .responseText, as this gives us bad results
	 * when YUI handles the request through an iframe (e.g. for file uploads)
	 * @see ADM-215
	 */
	if (!o.responseXML && !o.responseText && o.response) {
		o = o.response;
	}
	if (o.responseXML && o.responseXML.body) {
		return o.responseXML.body.innerHTML;
	} else if (o.responseText) {
		return o.responseText;
	} else {
		return "";
	}
}

Yaffas.UI.prototype.openTabs = function(o) {
	var div = document.getElementById('content');

	// check if we got a whole header which indicate a login page
	if (this.getResponseHTML(o).substr(0, 14) === "<!DOCTYPE html") {
		var c = new Element("div");
		var timeout = 0;
		c.innerHTML = this.getResponseHTML(o);

		var problems = c.select("div#problems");

		if (problems[0]) {
			try {
				var m = YAHOO.lang.JSON.parse(problems[0].innerHTML);
				if (typeof(m.timeout) !== "undefined") {
					timeout = 1;
				}
			}
			catch(err) {
			}
		}

		this.loading.hide();
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

		dlg.setHeader(_("lbl_logged_out", "global"));
		if (timeout === 1) {
			dlg.setBody(_("lbl_logged_out_timeout", "global"));
		} else {
			dlg.setBody(_("lbl_logged_out_msg", "global"));
		}
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
		return;
	}
	div.innerHTML = this.getResponseHTML(o);

	var sections = YAHOO.util.Dom.get("content");

	if (this.checkError()) {
		YAHOO.util.Dom.addClass(this.tabs, "hidden");
		return false;
	}

	for (var i = 0; i < sections.childNodes.length; ++i) {
		var section = sections.childNodes[i];

		if (section.className !== "section" && section.tagName !== "FORM") {
			continue;
		}

		console.log("section %o", section);
		var inputs = section.getElementsByTagName("input");
		var element = section.getElementsByTagName("h1")[0];
		if (element !== undefined) {
			var text = element.innerHTML;
			element.style.display = "none";
			var n = section.cloneNode(true);
			this.addTab(text, n);

			var oldselects = section.getElementsByTagName("select");
			var selects = n.getElementsByTagName("select");

			for (var j = 0; j < selects.length; ++j) {
				if (oldselects[j].getAttribute("multiple")) {
					var oldoptions = oldselects[j].options;
					var options = selects[j].options;

					for (var k = 0; k < options.length; k+=1) {
						options[k].selected = oldoptions[k].selected;
					}
				} else {
					selects[j].selectedIndex = oldselects[j].selectedIndex;
				}
			}

			var inputs = n.getElementsByTagName("input");
			var items = [];
			for (var j = 0; j < inputs.length; ++j) {
				if (inputs[j].getAttribute("type") === "submit") {
					inputs[j].id = YAHOO.util.Dom.generateId();
					items.push({
						id: inputs[j].id,
						disabled: (
							inputs[j].getAttribute("disabled") === "disabled" ? true : false)
					});
				}
			}

			if (n.tagName === "FORM") {
				n.id = YAHOO.util.Dom.generateId();
				YAHOO.util.Event.addListener(n.id, "submit",
					this.submitForm.bind(this));
			}

			for (var j = 0; j < items.length; ++j) {
				new YAHOO.widget.Button(items[j].id, items[j]);
			}
		}
		section.style.display = "none";
	}
	var contentNodes = document.getElementById("content");
	var childNodes = contentNodes.childNodes;
	while(childNodes.length) {
		contentNodes.removeChild(childNodes[0]);
	}
	this.tabs.selectTab(0);

	if (this.tabs.get("tabs").length === 0) {
		YAHOO.util.Dom.addClass(this.tabs, "hidden");
	} else {
		YAHOO.util.Dom.removeClass(this.tabs, "hidden");
	}

	this.loading.hide();
	return true;
};

Yaffas.UI.prototype.openPage = function(page){
	var panels = this.menu.getPanels();
	var i = 0;
	for (i = 0; i < panels.length; ++i) {
		var a = panels[i].getElementsByTagName("a")[0];
		if (YAHOO.util.Dom.hasClass(a, "active")) {
			break;
		}
	}
	YAHOO.util.History.navigate("m", page+"-"+i);
};

Yaffas.UI.prototype.openPageCall = function(page) {
	if (page === "") {
		return;
	}

	this.addCloseButton = false;

	this.moduleCleanup();

	page = page.split("-");
	this.menu.openPanel(page[1]);
	page = page[0];

	var sUrl = "/" + page + "/";
	// highlight current module
	YAHOO.util.Dom.removeClass(
		YAHOO.util.Dom.get("menuitem-"+this.currentPage),
		"menuitem-selected");
	YAHOO.util.Dom.addClass(
		YAHOO.util.Dom.get("menuitem-"+page),
		"menuitem-selected");
	this.currentPage = page;
	var div = document.getElementById('content');

	var callback = {
		success: this.replaceTabs,
		failure: this.handleFailure,
		argument: [],
		scope: this
	};
	this.loading.show();

	var request = YAHOO.util.Connect.asyncRequest('GET', sUrl, callback);
};

Yaffas.UI.prototype.moduleCleanup = function() {
	// cleanup old things
	YAHOO.util.Dom.get("response").innerHTML = "";

	if (typeof(module) !== "undefined") {
		if (typeof(module.cleanup) !== "undefined") {
			module.cleanup();
		}
		delete module;
	}
	var e;
	while (e = $("filter_form_c")) {
		e.remove()
	};
};

/**
 * Checks if the answer contains an error and shows the error dialog if
 * it does
 * 
 * @return true if error is found
 */
Yaffas.UI.prototype.checkError = function() {
	var errortext = "";

	// check for an unhandled perl error
	//
	// submitForm() results go to a response object, but
	// normal requests go to the content object
	var r = $('response');
	if (!r || !r.innerHTML) {
		r = $('content');
	}
	var perl_error_pos = r.innerHTML.indexOf(
			'<h1>Error - Perl execution failed</h1>');
	if (perl_error_pos != -1) {
		// Check if the typical string for fatal Perl errors is in the
		// response body.
		// In theory, this could lead to false positives (if a CGI script
		// really wants to print out the text above, but this is not
		// really likely in our setup.

		errortext = r.innerHTML.substr(perl_error_pos);

		// if this somehow ate the whole error message, revert back to the
		// whole response:
		if (!errortext) {
			errortext = "<h1>Perl error</h1><pre>" +
				escape(r.innerHTML) + "</pre>";
		}
	}

	if (!errortext) {
		// no perl error, so we'll check for a a yaffas error
		// (<div class="error">)
		var r = $('response').select('[class="error"]');
		if (r.length == 0) {
			r = $('content').select('[class="error"]');
		}

		if (r.length > 0) {
			// yaffas error found (class="error")
			var e = r[0].parentNode.getElementsByTagName("div");
			errortext = e[0].innerHTML;
			// remove the error text from the body
			r[0].parentNode.parentNode.innerHTML = "";
		}
	}

	if (!errortext) {
		// we're lucky, no (detectable) error occured, return early and
		// say checkError -> false
		return false;
	}

	// if any errortext was found, we show the error to the user
	// and return true so that the caller knows that indeed any error
	// occured
	this.loading.hide();
	this.errorDialog.setBody(errortext);
	this.errorDialog.show();
	return true;
};

Yaffas.UI.prototype.submitForm = function(e){
	try {
		YAHOO.util.Event.preventDefault(e);

		var element = e.srcElement || e.target;
		var input = element.getElementsByTagName("input");
		var upload = false;

		var args = Form.serializeElements(element.getElements(), {
			hash: true
		});

		for (var i = 0; i < input.length; ++i) {
			switch (input[i].type) {
				case "file":
					upload = true;
					break;
			}
		}

		var parseURL = function(url) {
			/* parseURL: returns the given URL, splitted into parts */

			// The <div> step is necessary for this to work on IE6
			var div = document.createElement("div");
			div.innerHTML = "<a></a>";
			div.firstChild.href = url;
			return div.firstChild;
		};

		var prepareForm = function() {
			YAHOO.util.Connect.setForm(element, upload);
		};
		YAHOO.util.Connect.setForm(element, upload);
		var url = element.action;
		var parsedURL = parseURL(url);
		var path = parsedURL.pathname.split('/');
		var querystring = parsedURL.search;
		if (path.length <= 2) {
			// The path component looks like this: /foo.cgi;
			// Splitting this string yields ["", "foo.cgi"];
			// By using this check we make sure that we're dealing with
			// an URL we are supposed to rewrite. This is necessary
			// in cases where forms use relative URLs -- these get
			// misinterpreted by the browser, as they are meant to be
			// interpreted relative to the module's directory, which the
			// browser doesn't know. So we'll re-insert it here.
			// If path.length is longer than 2, this means we have a path
			// to a subdirectory. In this case we'll leave it unmodified as
			// this is probably by intention of the module author.
			// This way modules can explicitly POST to other modules by
			// specifying an absolute URL.
			url = "/" + this.currentPage + "/" + path[path.length - 1];
			url += querystring;
		}
		this.submitURL(url, null, args, prepareForm);

	} catch (ex) {
		console.log(ex);
		this.loading.hide();
		this.errorDialog.setBody(ex.message);
		this.errorDialog.show();
	}
};

Yaffas.UI.prototype.submitURL = function(url, args, argsform,
		preprocess_func) {
	var handleSuccess = function(o) {
		console.log("response: %s", o.status);
		var r = YAHOO.util.Dom.get("response");
		r.innerHTML = parseScript(this.getResponseHTML(o));

		if (!this.checkError()) {
			this.loading.hide();

			if (typeof(o.argument.module) !== "undefined") {
				console.log("headers received: %s", o.getResponseHeaders);
				if (typeof(o.argument.module.savedForm) !== "undefined") {
					o.argument.module.savedForm(o.argument.url, o.argument.args);
				}
			}
		}
	};

	var callback = {
		success: handleSuccess,
		failure: this.handleFailure,
		upload: handleSuccess,
		argument: {
			"module": (typeof(module) !== 'undefined') ? module : undefined,
			url: url.split("/").pop(),
			args: args || argsform
		},
		scope: this
	};

	var submitArgs = args;

	var submit = function(additional) {
		this.loading.show();
		if (typeof(preprocess_func) !== "undefined") {
			preprocess_func();
		}
		var postData = [];
		if (submitArgs !== null || additional !== undefined) {
			for (var name in submitArgs) {
				postData.push(name + "=" + encodeURIComponent(submitArgs[name]));
			}
			for (var name in additional) {
				postData.push(name + "=" + encodeURIComponent(additional[name]));
			}
			YAHOO.util.Connect.asyncRequest('POST', url, callback, postData.join("&"));
		} else {
			// use data from form which was set by YAHOO.util.Connect.setForm
			YAHOO.util.Connect.asyncRequest('POST', url, callback);
		}
	}.bind(this);

	if (typeof(module) !== 'undefined' && typeof(module.confirmation) !== 'undefined') {
		if (! module.confirmation(url.split("/").pop(), args || argsform, submit)) {
			submit();
		}
	}	else {
		submit();
	}
};

Yaffas.UI.prototype.addTab = function(lab, c) {
	if (this.addCloseButton) {
		lab = '<span class="close"></span><span>' + lab + '</span>';
	}

	var tab = new YAHOO.widget.Tab({
		label: lab,
		contentEl: c
	});

	if (this.addCloseButton) {
		var e = tab.get('labelEl').getElementsByTagName('span')[0];
		YAHOO.util.Event.on(e, "click", function(ev) {
			YAHOO.util.Event.stopEvent(ev);
			this.closeTab(tab);
		}.bind(this));
	}

	this.tabs.addTab(tab);
};

Yaffas.UI.prototype.openTab = function(url, args, postFunc) {
	console.log("url %s %o", url, args);
	this.loading.show();

	var handleSuccess = function(o) {
		console.log("success");
		this.openTabs(o);
		this.replaceValueForm();
		this.tabs.selectTab(this.tabs.get("tabs").length-1);
		if (typeof postFunc !== "undefined") {
			postFunc();
		}
	};

	var callback = {
		success: handleSuccess,
		failure: this.handleFailure,
		argument: [],
		scope: this
	};

	var postData = [];

	for (var name in args) {
		postData.push(name + "=" + args[name]);
	}

	var request = YAHOO.util.Connect.asyncRequest('POST', url,
		callback, postData.join("&"));
};

Yaffas.UI.prototype.closeTab = function(t) {
	var tab = t || this.tabs.get("activeTab");
	var i = this.tabs.getTabIndex(tab);

	if (typeof module !== "undefined" && typeof module.beforeCloseTab !== "undefined") {
		module.beforeCloseTab(i, tab);
	}

	this.tabs.removeTab(tab);
	this.selectTab(0);

	if (typeof module !== "undefined" && typeof module.afterCloseTab !== "undefined") {
		module.afterCloseTab(i, tab);
	}
};

Yaffas.UI.prototype.resetTab = function() {
	var e = this.tabs.get("activeTab").get("contentEl");

	if (e.tagName === "FORM") {
		e.reset();
	}
};

Yaffas.UI.prototype.reloadTabs = function() {
	this.loading.show();
	this.openPageCall(YAHOO.util.History.getCurrentState("m"));
};

Yaffas.UI.prototype.selectTab = function(t) {
	this.tabs.selectTab(t);
};

Yaffas.UI.prototype.handleFailure = function(o) {
	var errorMsg = this.getResponseHTML(o);

	if (!errorMsg && o.statusText) {
		if (o.statusText === "communication failure") {
			errorMsg = _("err_connection_failed", "global");
		} else {
			errorMsg = o.statusText;
		}
	}
	if (!errorMsg) {
		errorMsg = "An undefined error occured!";
	}
	this.loading.hide();
	this.errorDialog.setBody(errorMsg);
	this.errorDialog.show();
}

Yaffas.UI.prototype.logout = function() {
	console.log("logout");
	location.replace("/session_login.cgi?logout=1");
};

Yaffas.UI.prototype.setLanguage = function(lang){
	console.log("select lang %s", lang);

	var callback = {
		success: function() {
			location.replace("/");
		},
		failure: this.handleFailure,
		arguments: [],
		scope: this
	};
	this.loading.show();
	YAHOO.util.Connect.asyncRequest('POST', "/changelang/check_lang.cgi",
		callback, "lang=" + lang);
};

Yaffas.UI.prototype.openAbout = function() {
	this.openPage("about");
};

Yaffas.UI.prototype.openHelp = function() {
	if (Yaffas.CONFIG["theme"] == "bitkit") {
		window.open("http://doc.bitkit.com");
	} else if (Yaffas.CONFIG["theme"] == "zadmin") {
		window.open("http://doc.zarafa.com/trunk/ZAdmin/en-US/html/");
	} else {
		window.open("http://doc.yaffas.org/");
	}
};

Yaffas.UI.prototype.replaceValueForm = function() {
	var t = YAHOO.util.Dom.getElementsByClassName("value_add_del_form");

	if (t.length == 0) {
		t = YAHOO.util.Dom.getElementsByClassName("small_form");
	}

	for (var i = 0; i < t.length; ++i) {
		var form = t[i].up("form");
		var action = form.action.split("/").pop();
		action = Yaffas.ui.currentPage + "/" + action;

		var elements = t[i].getElementsByTagName("div");
		for (var j = 0; j < elements.length; ++j) {
			Yaffas.list.handleClick(elements[j], action);
		}
	}
};

/**
 * showHelp(elem): Displays the help div after a delay of 200ms
 */
Yaffas.UI.prototype.showHelp = function(elem) {
	this.showHelpTooltip = true;
	var e = new YAHOO.util.Element(elem.children[0]);
	e.addClass("show");

	if (e.hasClass("hidden")) {
		var func = function() {
			if (e.hasClass("show")) {
				$$(".tooltip div:not(.hidden)").each(function(a) { a.addClassName("hidden") });
				e.removeClass("hidden");
				e.removeClass("show");
			}
		}.bind(this);
		func.delay(0.2);
	}
};

/**
 * cancelHelp(elem): Cancel the help showing if delay has not been reached
 */
Yaffas.UI.prototype.cancelHelp = function(elem) {
	this.showHelpTooltip = false;
	var e = new YAHOO.util.Element(elem.children[0]);
	e.removeClass("show");
};

/**
 * toggleHelp(e): Toggles visibility on help element
 */
Yaffas.UI.prototype.toggleHelp = function(elem) {
	var e = new YAHOO.util.Element(elem.children[0]);

	if (e.hasClass("hidden")) {
		$$(".tooltip div:not(.hidden)").each(function(a) {
			a.addClassName("hidden")
		});
		e.removeClass("hidden");
		e.removeClass("show");
	} else {
		e.addClass("hidden");
		e.removeClass("show");
	}
};

Yaffas.UI.prototype.reloadGlobals = function() {
	YAHOO.util.Get.script("/globals.cgi", {
		onSuccess: function() {
			console.log("loaded Script")
		}
	});
};

Yaffas.UI.prototype.getActiveTabEl = function() {
	return this.tabs.get("activeTab").get("contentEl");
};

/* vim: set noet sw=2 ts=2: */
