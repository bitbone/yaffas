Yaffas.List = function(){

}

Yaffas.List.prototype.remove = function(n, v){
	var tab = Yaffas.ui.tabs.get("activeTab").get("contentEl");
    var e = Element.select(tab, '[name="'+n+'"]');
	
    for (var i = 0; i < e.length; ++i) {
        if (e[i].getAttribute("value") === v) {
            e[i].parentNode.parentNode.remove();
        }
    }
}

Yaffas.List.prototype.add = function(n, v, a){
    var t = YAHOO.util.Dom.getElementsByClassName("small_form", "table", Yaffas.ui.tabs.get("activeTab").get("contentEl"));
    var l = t[0].rows.length;
    var row = t[0].insertRow(l);
    
    var cellLeft = row.insertCell(0);
    var textNode = document.createTextNode(v);
    cellLeft.appendChild(textNode);
    
    var cellRight = row.insertCell(1);
    var input = document.createElement("div");
    input.setAttribute("value", v);
    input.setAttribute("name", n);
    Yaffas.list.handleClick(input, a);
    
    cellRight.appendChild(input);
}

Yaffas.List.prototype.handleClick = function(e, action){
    YAHOO.util.Event.addListener(e, "click", function(e){
        var args = {};
        args[e.getAttribute("name")] = e.getAttribute("value");
        Yaffas.ui.submitURL(action, args);
    }.bind(this, e));
}
