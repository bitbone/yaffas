function ZarafaConf(){
    new YAHOO.util.Resize("message_warn");
    new YAHOO.util.Resize("message_soft");
    new YAHOO.util.Resize("message_hard");
    
    var s = YAHOO.util.Dom.get("filtersetting");
    
    if (typeof s !== "undefined" && s) {
        toggle_filtergroup(s.value);
    }

    var createprf = new YAHOO.widget.Button("btncreateprf");

    createprf.on("click", function() {
        var args = $$("[name=createprf]")[0].serialize();
        window.open("/zarafaconf/createprf.cgi?"+args);
        window.close();
    });
}

ZarafaConf.prototype.confirmation = function(url, args, submit) {
	if (url != "basicsettings.cgi") {
		// submit immediately
		return;
	}

	if ($("filtertype") === null) {
		// return if no user filter is available
		return;
	}

	var ft = $("filtertype").value;
	var fg = $("filtergroup").value;
    
	if (ft <= 0) {
		// filter 0 ("default") never leads to users being deleted,
		// so we submit instantly
		return;
	}
	var callback = {
		success: function(r) {
			var o = YAHOO.lang.JSON.parse(r.responseText);

			if (YAHOO.lang.isArray(o) && o.length > 0) {
				// the new filter will lead to users being deleted,
				// so we ask the user if he is sure...
				var d = new Yaffas.Confirm(
					_("lbl_confirm_filter_save"),
					_("lbl_confirm_msg") + dlg_arg(o),
					submit);
				d.show();
			} else {
				// no users will be deleted, so we proceed without asking
				submit();
			}
		},
		failure: Yaffas.ui.handleFailure,
		scope: this
	};

	YAHOO.util.Connect.asyncRequest("POST", "/zarafaconf/deletedusers.cgi",
		callback, args);

	// delay submitting
	return true;
}

function toggle_filtergroup(selected){
    var array = document.getElementsByName("filtergroup");
    for (var i = 0; i < array.length; i++) {
			  // we use visibility and not display to avoid content "jumping"
        if (selected == 2) {
            array[i].style.visibility = "visible";
        }
        else {
            array[i].style.visibility = "hidden";
        }
    }
}

module = new ZarafaConf();
