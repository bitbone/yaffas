/**
 * Pluginpasswd
 * Some sort of doing it with a trick was used to expand the tabs in settings because there is no known direct way to add a tab.
 */
Pluginpasswd.prototype = new Plugin;
Pluginpasswd.prototype.constructor = Pluginpasswd;
Pluginpasswd.superclass = Plugin.prototype;

function Pluginpasswd(){}

Pluginpasswd.prototype.init = function(){
	this.registerHook("client.dialog.general.onload.after");
}

Pluginpasswd.prototype.execute = function(eventID, data){
	var action_URL = window.location.search;
/* Ensure that this only takes place if task is explicitly open settings, just to trigger on open is a maybe a
   bit to much risk */
	if (action_URL.search("task=open_settings") >= 0) {
    		switch(eventID) {
			case "client.dialog.general.onload.after":
				this.dialogInformation(data);
				break;
		}
	};
}

Pluginpasswd.prototype.dialogInformation = function(data) {
	if (data["task"] == "open") {
    	    var tabbar		= window.document.getElementById("tabbar");
	    var tab_ul		= tabbar.firstChild;
	    var tabnew		= dhtml.addElement(tab_ul,"li",false,"tab_pwdchange", "");
	    var tabpwdchange	= dhtml.addElement(tabnew,"span",false,false, _("Change Password","plugin_passwd"));
	    webclient.tabbar.pages["pwdchange"] = _("Change Password","plugin_passwd");
	    dhtml.addEvent(webclient.tabbar,tabnew, "mouseover", eventTabBarMouseOver);
	    dhtml.addEvent(webclient.tabbar,tabnew, "click", eventTabBarClick);
	    dhtml.addEvent(webclient.tabbar,tabnew, "mouseover", eventTabBarMouseOver);
	    dhtml.addEvent(webclient.tabbar,tabnew, "mouseout", eventTabBarMouseOut);
	};
};


