function ZarafaWebaccess(){

	this.setupTable();
}

ZarafaWebaccess.prototype.setupTable = function() {
	var myColumnDefs = [
    {
        key: "option",
        label: _("lbl_option"),
        sortable: true,
		hidden: true,
	}, {
		key: "label",
		label: _("lbl_option"),
		sortable: true,
	}, {
        key: "state",
        label: _("lbl_state"),
        sortable: true,
		formatter: function(e, record, column, data){
			var disabled = "";

			e.innerHTML = "<input type='checkbox' "+((data === 1) ? "checked" : "")+" />";

			YAHOO.util.Event.addListener(e.getElementsByTagName("input")[0], "click", function() {
				console.log("clicked %s %s", this.checked, record.getData().option);
				Yaffas.ui.submitURL("/zarafawebaccess/options.cgi", {service: record.getData().option, value: this.checked ? "1" : "0"})
			})
    	}
    }];
	this.usertable = new Yaffas.Table({
		container: "options",
		columns: myColumnDefs,
		url: "/zarafawebaccess/options.cgi",
		sortColumn: 0
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

module = new ZarafaWebaccess();
