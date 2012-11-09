/**
 * @param {Object} args settings object
 * mandatory keys: columns, container, url
 * optional keys: sortColumn, sortOrder, selectionMode(standard, single, singlecell, cellblock, cellrange)
 */
Yaffas.Table = function(args){
    this.columns = args.columns;
    this.container = args.container;
    this.url = args.url;
    this.sortcolumn = args.sortColumn || 0;
    this.sortorder = args.sortOrder || YAHOO.widget.DataTable.CLASS_ASC;
    this.selectionmode = args.selectionMode || "single";
    this.hidePages = args.hidePages || false;
    this.hideFilter = args.hideFilter || false;
    this.config = args.config || false;
    this.table = null;
    this.source = null;
	this.filterform = null;
    this.parameters = {};
    this.setupTable();
}

YAHOO.widget.DataTable.prototype.requery = function(newRequest){
    var ds = this.getDataSource();
    
    this.showTableMessage(this.get("MSG_LOADING"));
    
    if (ds instanceof YAHOO.util.LocalDataSource) {
        ds.liveData = newRequest;
        ds.sendRequest("", {
            success: this.onDataReturnInitializeTable,
            failure: this.onDataReturnInitializeTable,
            scope: this,
            argument: this.getState()
        });
    }
    else {
        ds.sendRequest((newRequest === undefined ? this.get('initialRequest') : newRequest), {
            success: this.onDataReturnInitializeTable,
            failure: this.onDataReturnInitializeTable,
            scope: this,
            argument: this.getState()
        });
    }
}

Yaffas.Table.prototype.natsort = function (a, b, order, field) {
	if (order)
		return natcompare(b.getData()[field], a.getData()[field]);
	else
		return natcompare(a.getData()[field], b.getData()[field]);
}


Yaffas.Table.prototype.setupTable = function(){
    var myConfigs = $H({
        dynamicData: false,
        selectionMode: this.selectionmode,
        "MSG_LOADING": _("lbl_loading_data", "global"),
        "MSG_ERROR": _("lbl_error_data", "global"),
        "MSG_EMPTY": _("lbl_no_data", "global")
    });

    if (this.config != false) {
        myConfigs.update(this.config)
    }
    myConfigs = myConfigs.toObject();

    if (!this.hidePages) {
        var f = _("lbl_table_pager");
        if (!this.hideFilter) {
            f += "<a href='#' class='filter_toggle'>"+_("lbl_filter_show")+"</a>";
        }

        myConfigs["paginator"] = new YAHOO.widget.Paginator({
            rowsPerPage: 15,
            container: "datapager",
            template: f,
            alwaysVisible: false,
            rowsPerPageOptions: [10, 15, 25, 50, 75, 100],
            pageLinks: 5,
            pageLabelBuilder: function(page, paginator){
                var recs = paginator.getPageRecords(page);
                return (recs[0] + 1) + ' - ' + (recs[1] + 1);
            }
        });
    }
    
    this.source = new YAHOO.util.XHRDataSource(this.url);
    this.source.maxCacheEntries = 10;
    this.source.responseType = YAHOO.util.XHRDataSource.TYPE_JSON;
    this.source.responseSchema = {
        resultsList: "Response",
        fields: this.columns,
        metaFields: {
            totalRecords: "totalRecords"
        }
    };
    this.source.filterarg = {};

	// this function is applied on data before it gets displayed
    this.source.doBeforeCallback = function(req, raw, res, cb){
        if (this.filterarg) {
            var data = res.results || [], i, filtered = [];
            
            for (i = 0; i < data.length; ++i) {
                var matched = true;
                
                for (var name in this.filterarg) {
                    if (typeof data[i][name] !== "undefined") {
                        // convert everything to string
                        data[i][name] = data[i][name]+"";
                        if (data[i][name].indexOf(this.filterarg[name], 0) < 0) {
                            matched &= false;
                        }
                    }
                }
                if (matched) {
                    filtered.push(data[i]);
                }
            }
			return {results: filtered, meta: res.meta};
        }
        
        return res;
    }
    
    this.source.sendRequest = function(oRequest, oCallback, oCaller){
        // First look in cache
        var oCachedResponse = this.getCachedResponse(oRequest, oCallback, oCaller);
        if (oCachedResponse) {
            oCachedResponse = this.doBeforeCallback(oRequest, oCachedResponse, oCachedResponse, oCallback);
            YAHOO.util.DataSourceBase.issueCallback(oCallback, [oRequest, oCachedResponse], false, oCaller);
            return null;
        }
        
        // Not in cache, so forward request to live data
        return this.makeConnection(oRequest, oCallback, oCaller);
    }
    
    this.source.subscribe("dataErrorEvent", Yaffas.ui.handleFailure);

	for (var i = 0; i < this.columns.length; ++i) {
		if (typeof this.columns[i].sortOptions === "undefined") {
			this.columns[i].sortOptions = {};
			this.columns[i].sortOptions.sortFunction = this.natsort;
		}
	}
    
    this.table = new YAHOO.widget.DataTable(this.container, this.columns, this.source, myConfigs);

    this.table.handleDataReturnPayload = function(oRequest, oResponse, oPayload) {
        oPayload.totalRecords = oResponse.meta.totalRecords;
        return oPayload;
    }

    this.table.subscribe("postRenderEvent", function(){
        if (this.sortcolumn >= 0) {
            this.table.sortColumn(this.table.getColumn(this.sortcolumn), this.sortorder);
        }
        this.table.unsubscribe("postRenderEvent");
	    this.createFilterView();
    }
.bind(this));
    
    this.table.subscribe("rowMouseoverEvent", this.table.onEventHighlightRow);
    this.table.subscribe("rowMouseoutEvent", this.table.onEventUnhighlightRow);
    this.table.subscribe("rowClickEvent", this.table.onEventSelectRow);
}

Yaffas.Table.prototype.createFilterView = function(){
    if (this.hideFilter) {
        return;
    }
    if (!this.filterform) {
		var i, ret = "", labels = {};
	    
	    ret += "<div class='hd'>"+_("lbl_filter_header")+"</div>";
	    ret += "<div class='bd'>";
	    ret += "<table>";
	    for (i = 0; i < this.columns.length; ++i) {
	        var col = this.columns[i];
			if (!col.hidden) {
				var id = YAHOO.util.Dom.generateId();
		        ret += "<tr><td>" + col.label + ":</td><td><input type='text' id='" + id + "' /></td></tr>";
		        labels[col.key] = id;
			}
	    }
	    ret += "</table></div>";
	    
	    var d = document.createElement("div");
	    d.id = "filter_form";
	    d.innerHTML = ret;
		var container = $(this.container);
	    
	    $(this.container).parentNode.insertBefore(d, $(this.container));
	    
	    for (i in labels) {
			var filterlistener =  function(l){
	            this.source.filterarg = {};
				for (var l in labels) {
					try {
						var value = $(labels[l]).value;
		                if (value !== "undefined" && value != "") {
		                    this.source.filterarg[l] = value;
		                }
					} catch (e) {
					}
				}
	            this.reload(true)
	        };
	        YAHOO.util.Event.addListener(labels[i], "keyup", filterlistener.bind(this));
	    }
	    
	    this.filterform = new YAHOO.widget.Dialog(d, {
	        visible: false,
	        fixedcenter: true,
	        modal: false,
	        zIndex: 100,
	    });
		
	    this.filterform.hideEvent.subscribe(function() {
			this.source.filterarg = {};
			Array.from(this.filterform.element.getElementsByTagName("input")).each(function(e) {e.value = ""});
			this.reload(true);
		}.bind(this));
	    this.filterform.render(document.body);
		
		var btns = Array.from(Yaffas.ui.tabs.get("activeTab").get("contentEl").getElementsByClassName("filter_toggle"));
		
		btns.each(function(item) {
			YAHOO.util.Event.addListener(item, "click", function(e) {
				e.preventDefault();
				this.filterform.show();
				return false;
			}.bind(this));
		}.bind(this))
	}
}

Yaffas.Table.prototype.selectedRows = function(){
    var s = this.table.getSelectedTrEls();
    var ret = [];
    
    for (var i = 0; i < s.length; ++i) {
        var r = s[i].childNodes;
        ret.push([]);
        for (var j = 0; j < r.length; ++j) {
            if (r[j].innerText) {
                ret[i].push(r[j].innerText);
            }
            else {
                ret[i].push(r[j].textContent);
            }
        }
    }
    return ret;
}

Yaffas.Table.prototype.reload = function(useCache){
	if (!useCache)
		this.source.flushCache();

    this.table.requery();
    this.table.subscribe("postRenderEvent", function(){
        this.table.sortColumn(this.table.getColumn(this.sortcolumn), this.sortorder);
        this.table.unsubscribe("postRenderEvent");
    }
.bind(this));
}

Yaffas.Table.prototype.destroy = function() {
    if (typeof this.filterform !== "undefined" && this.filterform !== null) {
        this.filterform.destroy();
    }
}
