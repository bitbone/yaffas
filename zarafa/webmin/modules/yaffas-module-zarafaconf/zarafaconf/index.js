function ZarafaConf(){

    var b = YAHOO.util.Dom.get("savefilter");
    
    if (b) {
        var btn = new YAHOO.widget.Button(b);
        
        btn.on("click", this.showDeleteUsers.bind(this));
    }
    
    
    new YAHOO.util.Resize("message_warn");
    new YAHOO.util.Resize("message_soft");
    new YAHOO.util.Resize("message_hard");
    
    
    var s = YAHOO.util.Dom.get("filtersetting");
    
    if (typeof s !== "undefined" && s) {
        toggle_filtergroup(s.innerHTML.strip());
    }
}

ZarafaConf.prototype.showDeleteUsers = function(){
    var ft = $("filtertype").value;
    var fg = $("filtergroup").value;
    
    if (ft > 0) {
        var callback = {
            success: function(r){
                var o = YAHOO.lang.JSON.parse(r.responseText);
                
                if (YAHOO.lang.isArray(o) && o.length > 0) {
                    var d = new Yaffas.Confirm(_("lbl_confirm_filter_save"), _("lbl_confirm_msg") + dlg_arg(o), this.setFilter.curry(ft, fg));
                    d.show();
                }
                else {
                    this.setFilter(ft, fg);
                }
            },
            failure: Yaffas.ui.handleFailure,
            scope: this
        }
        
        var args = "filtertype=" + ft + "&filtergroup=" + fg;
        
        YAHOO.util.Connect.asyncRequest("POST", "/zarafaconf/deletedusers.cgi", callback, args);
    }
    else {
        this.setFilter(ft, fg);
    }
}

ZarafaConf.prototype.setFilter = function(ft, fg){
    Yaffas.ui.submitURL("/zarafaconf/filteruser.cgi", {
        filtergroup: fg,
        filtertype: ft
    });
    
}

function getElementsByClass(searchClass, node, tag){
    var classElements = new Array();
    if (node == null) 
        node = document;
    if (tag == null) 
        tag = '*';
    var els = node.getElementsByTagName(tag);
    var elsLen = els.length;
    var pattern = new RegExp("(^|\\\\s)" + searchClass + "(\\\\s|$)");
    for (i = 0, j = 0; i < elsLen; i++) {
        if (pattern.test(els[i].className)) {
            classElements[j] = els[i];
            j++;
        }
    }
    return classElements;
}

function toggle_filtergroup(selected){
    var array = getElementsByClass("filtergroup");
    for (var i = 0; i < array.length; i++) {
        if (selected == 2) {
            array[i].style.display = "table-cell";
        }
        else {
            array[i].style.display = "none";
        }
    }
}

module = new ZarafaConf();
