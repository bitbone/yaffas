Yaffas.Menu = function(s){
    this.container = s.container || "menu";
    this.trigger = s.trigger || null;
    this.items = s.items || [];
    this.multiselect = s.multiselect || false;
    
    this.menu = null;
    this.setup();
}

Yaffas.Menu.prototype.setup = function(){
    this.menu = new YAHOO.widget.ContextMenu(this.container, {
        trigger: this.trigger,
        lazyload: true,
        itemdata: []
    });
    this.menu.addItems(this.items);
    this.menu.multiselect = this.multiselect;
    
    var onTriggerContextMenu = function(e){
        var target = this.contextEventTarget;
        
        console.log("contextmenu triggered");
        
        if (!YAHOO.util.Dom.hasClass(target, "yui-dt-liner")) {
            this.cancel();
        }
    }
    
    function onContextMenuBeforeShow(p_sType, p_aArgs){
        var target = this.contextEventTarget;
        
        if (this.getRoot() == this) {
            var selectedTR = target.nodeName.toUpperCase() == "TR" ? target : YAHOO.util.Dom.getAncestorByTagName(target, "TR");
            
            var s = YAHOO.util.Dom.getElementsByClassName("yui-dt-selected");
            
            if (this.multiselect === false) {
                // clear all states
                for (var i = 0; i < s.length; ++i) {
                    YAHOO.util.Dom.removeClass(s[i], "yui-dt-selected");
                }
            }
            
            YAHOO.util.Dom.addClass(selectedTR, "yui-dt-selected");
            
            this.render();
        }
    }
    
    this.menu.subscribe("triggerContextMenu", onTriggerContextMenu);
    this.menu.subscribe("beforeShow", onContextMenuBeforeShow);
    this.menu.render(document.body);
}

Yaffas.Menu.prototype.destroy = function(){
    this.menu.destroy();
}
