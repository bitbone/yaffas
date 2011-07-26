var Restore = function() {
    this.restorekeys = [];
    this.restoreDialog = null;
    this.restoreStatus = null;

    var submit = function() {
        Yaffas.ui.submitURL("/zarafabackup/restore.cgi", {keys: escape(this.restorekeys.toJSON())});

        $("restoremessage").innerHTML = _("lbl_restore_started");
        $("restoreloading").style.display = "block";
        this.restoreDialog.cfg.setProperty("buttons", this.buttonsRestoreStarted)
        this.restoreDialog.setHeader(_("lbl_restore_running"));

        this.restoreStatus = new PeriodicalExecuter(this.updateRestoreStatus.bind(this), 2);
    };

    this.buttonsRestoreIdle = [
        {
            text: _("lbl_restore"),
            handler: submit.bind(this)
        }, {
            text: _("lbl_cancel"),
            handler: function(){
                this.cancel();
            }
        }
    ];
    this.buttonsRestoreStarted = [
        {
            text: _("lbl_stop"),
            handler: this.stop.bind(this)
        }
    ];
    this.buttonsRestoreFinished = [
        {
            text: _("lbl_close"),
            handler: this.finish.bind(this)
        }
    ];
}

Restore.prototype.start = function() {
    this.restoreDialog.center();
    this.restoreDialog.show();
}

Restore.prototype.stop = function() {
    $("restoreloading").style.display = "none";
    this.restoreStatus.stop();
    this.restoreDialog.cfg.setProperty("buttons", this.buttonsRestoreFinished);
    this.restoreDialog.setHeader(_("lbl_restore_finished"));
}

Restore.prototype.finish = function() {
    this.restoreDialog.hide();
    this.restoreStatus.stop();
    this.restoreDialog.cfg.setProperty("buttons", this.buttonsRestoreIdle);
    $("restoremessage").innerHTML = "";
    $("restoreloading").style.display = "none";
    this.restoreDialog.setHeader(_("lbl_restore_start"));
    this.restorekeys.splice(0, this.restorekeys.length);
    this.fillRestoreKeys();
}

Restore.prototype.add = function(restore) {
    var exists = false;

    for (var i = 0; i < this.restorekeys.length; ++i) {
        if ( this.restorekeys[i].id === restore.id &&
            this.restorekeys[i].label === restore.label &&
            this.restorekeys[i].day === restore.day &&
            this.restorekeys[i].recursive === restore.recursive &&
            this.restorekeys[i].store === restore.store ) {
            exists = true;
            break;
        }
    }

    if (!exists) {
        this.restorekeys.push(restore);
        this.fillRestoreKeys();
    }
}

Restore.prototype.fillRestoreKeys = function() {
    this.restoretable.requery(this.restorekeys);
    Yaffas.ui.tabs.getTab(1).set("label", _("lbl_restore")+" ("+this.restorekeys.length+")")
}

Restore.prototype.remove = function() {
    var rows = this.restoretable.getSelectedRows();
    var remove = [];

    for (var i = 0; i < rows.length; ++i) {
        var store = this.restoretable.getRecord(rows[i]).getData("store");
        var day = this.restoretable.getRecord(rows[i]).getData("day");
        var id = this.restoretable.getRecord(rows[i]).getData("id");


        for (var j = 0; j < this.restorekeys.length; ++j) {
            if (this.restorekeys[j].day === day &&
                this.restorekeys[j].id === id &&
                this.restorekeys[j].store === store) {
                remove.push(j);
            }
        }
    }

    remove = remove.uniq().sort(function(a,b) {return a-b;}).reverse();

    for (var i = 0; i < remove.length; ++i) {
        this.restorekeys.splice(remove[i], 1);
    }
    this.fillRestoreKeys();
}

Restore.prototype.clear = function() {
    this.restorekeys.splice(0, this.restorekeys.length);
    this.fillRestoreKeys();
}

Restore.prototype.updateRestoreStatus = function() {
    var message = $("restoremessage");
    var handleUpdate = function(oResponse) {
        try {
            var r = YAHOO.lang.JSON.parse(oResponse.responseText);
            if (YAHOO.lang.isObject(r.Response)) {
                r = r.Response;
                if (r.done) {
                    this.stop();
                }
                if (r.status) {
                    message.innerHTML = r.status;
                }
            }
        } catch (x) {
            alert("Error: "+x);
        }
    }

    var callback = {
        success: handleUpdate,
        failure: Yaffas.ui.handleFailure,
        scope: this
    };
    YAHOO.util.Connect.asyncRequest("GET", "/zarafabackup/restore-status.cgi", callback);
}

Restore.prototype.setupUI = function() {
    this.setupButton();
    this.setupDialog();
    this.setupTable();
}

Restore.prototype.setupButton = function() {
    var btn = new YAHOO.widget.Button("btn_restore");
    btn.on("click", function() {
            this.start()
        }.bind(this));

    btn = new YAHOO.widget.Button("btn_clear");
    btn.on("click", function() {
            var dlg = new Yaffas.Confirm(_("lbl_really_clear"),
                _("lbl_clear_msg"),
                function() {
                    this.clear();
                }.bind(this));
            dlg.show();
        }.bind(this)
    );
}

Restore.prototype.setupDialog = function() {
    this.restoreDialog = new YAHOO.widget.Dialog("restoredlg", {
            visible: false,
            fixedcenter: false,
            width: "800px",
            modal: false,
            close: false,
            buttons: this.buttonsRestoreIdle
        });
    this.restoreDialog.render();
    this.restoreDialog.hide();
}

Restore.prototype.setupTable = function() {
    var myColumnDefs = [
            {
                key: "id",
                label: "ID",
                sortable: true,
                hidden: true,
            }, {
                key: "label",
                label: _("lbl_subject"),
                sortable: true,
            }, {
                key: "store",
                label: _("lbl_store"),
                sortable: true,
            }, {
                key: "day",
                label: _("lbl_backup"),
                sortable: true,
            }
    ];

    this.restoresource = new YAHOO.util.LocalDataSource(this.restorekeys);
    this.restoresource.responseType = YAHOO.util.DataSource.TYPE_JSARRAY;
    this.restoresource.responseSchema = {
        fields: ["label", "store", "day", "id"]
    };
    this.restoretable = new YAHOO.widget.DataTable("lst_restore", myColumnDefs, this.restoresource);
    this.restoretable.subscribe("rowMouseoverEvent", this.restoretable.onEventHighlightRow);
    this.restoretable.subscribe("rowMouseoutEvent", this.restoretable.onEventUnhighlightRow);
    this.restoretable.subscribe("rowClickEvent", this.restoretable.onEventSelectRow);

    var i = [
        {
            text: _("lbl_remove"),
            onclick: {
                fn: this.remove.bind(this)
            }
        }
    ];

    this.restoremenu = new Yaffas.Menu({ container: "restoretablemenu", trigger: "lst_restore", items: i, multiselect: true });
}

Restore.prototype.cleanup = function() {
	if (this.restoremenu) {
		this.restoremenu.destroy();
		this.restoremenu = null;
	}
}

/* ------------------------------------------------------------------------ */

var Backup = function(){
    YAHOO.util.Get.css("/zarafabackup/index.css");

    this.layout = {};
    this.tree = {};
    this.main = {};
    this.table = null;
    this.selectedDay = null;
    this.selectedFolder = null;
    this.selectedStore = null;

    this.restore = new Restore();
    this.restore.setupUI();
}

Backup.prototype.selectBackupDate = function(d) {
    this.tree.removeChildren(this.tree.getRoot());
    this.selectedFolder = null;
    this.selectedStore = null;
    this.selectedDay = null;
    if (d) {
        this.selectedDay = d;
        this.loadStores(d);
        if (this.table !== null) {
            this.table.destroy();
            this.table = null;
            $("mainpane").innerHTML = "";
        }
    }
    else {
        if (this.table !== null) {
            this.table.destroy();
            this.table = null;
            $("mainpane").innerHTML = "";
        }
        this.tree.render();
    }
}

Backup.prototype.fillBackupDates = function() {
    var sUrl = "/zarafabackup/sets.cgi";

    var callback = {
        success: function(oResponse) {
            try {
                var r = YAHOO.lang.JSON.parse(oResponse.responseText);

                var obj = r.Response;

                var l = $("backupselect");

				if (obj.length === 0) {
						var o = new Option(_("lbl_no_backup"), "");
						l[0] = o;
				}
				else {
					for (var i = 0; i < obj.length; ++i) {
						var o = new Option(obj[i].name, obj[i].value);

						l[l.length] = o;
					}
				}

                YAHOO.util.Event.addListener("backupselect", "change", function(e) {
                        var e = $$('#backupselect option').find(function(ele){return !!ele.selected})
                        if (typeof e !== "undefined") {
                            this.selectBackupDate(e.value);
                        }
                    }.bind(this));
            } catch (x) {
                alert("Error: "+x);
            }
        }.bind(this),
        failure: function(oResponse) {
            YAHOO.log("Failed to process XHR transaction.", "info", "example");
        },
        timeout: 60000
    };

    YAHOO.util.Connect.asyncRequest('GET', sUrl, callback);
}

Backup.prototype.addRestoreFolder = function() {
    var node = this.currentFolderNode;
    var store = this.selectedStore.label;
    this.restore.add({"id": node.data.restorekey, "store": store, day: this.selectedDay, "label": node.label, "recursive": 1});
}

Backup.prototype.addRestoreMessage = function() {
    var s = this.table.selectedRows();

    if (s.length > 0) {
        for (var i = 0; i < s.length; ++i) {
            var id = s[i][0];
            var store = this.selectedStore.label;
            this.restore.add({"day": this.selectedDay, "store": store, "id": id, "label": s[i][1], "recursive": 0});
        }
    }
}


Backup.prototype.loadStores = function(d)  {
    var sUrl = "/zarafabackup/stores.cgi?date="+encodeURI(d);

    var callback = {
        success: function(oResponse) {
            try {
                var r = YAHOO.lang.JSON.parse(oResponse.responseText);

                var obj = r.Response;
                var root = this.tree.getRoot();

                for (var i = 0; i < obj.length; ++i) {
                    var textnode = new YAHOO.widget.TextNode(obj[i], root, false);
                    textnode.setDynamicLoad(this.loadFolders.bind(this));
                    textnode.labelStyle = "icon-store";
                }

                this.tree.render();
            } catch (x) {
                alert("Error: "+x);
            }
        }.bind(this),
        failure: function(oResponse) {
            YAHOO.log("Failed to process XHR transaction.", "info", "example");
        },
        timeout: 7000
    };

    YAHOO.util.Connect.asyncRequest('GET', sUrl, callback);
}

Backup.prototype.loadFolders = function(node, fnLoadComplete) {
    var sUrl = "/zarafabackup/folders.cgi?store="+encodeURI(node.label)+"&day="+encodeURI(this.selectedDay);

    var callback = {
        success: function(oResponse) {
            try {
                var r = YAHOO.lang.JSON.parse(oResponse.responseText);

                if (YAHOO.lang.isArray(r.Response) && r.Response[0].children !== "undefined") {
                    var obj = r.Response[0].children;

                    function build(obj, root) {
                        for (var i = 0; i < obj.length; ++i) {
                            var textnode = new YAHOO.widget.TextNode({ label: obj[i].label, id: obj[i].id, type: obj[i].type, restorekey: obj[i].restorekey }, root, false);
                            switch(obj[i].type) {
                            case "IPF.Contact":
                                textnode.labelStyle = "icon-contact";
                                break;
                            case "IPF.StickyNote":
                                textnode.labelStyle = "icon-note";
                                break;
                            case "IPF.Appointment":
                                textnode.labelStyle = "icon-calendar";
                                break;
                            case "IPF.Journal":
                                textnode.labelStyle = "icon-journal";
                                break;
                            case "IPF.Task":
                                textnode.labelStyle = "icon-task";
                                break;
                            case "IPF.Note.OutlookHomepage":
                            default:
                                textnode.labelStyle = "icon-folder";

                            }
                            if (obj[i].children.length > 0) {
                                build(obj[i].children, textnode, false);
                            }
                        }
                    }

                    build(obj, oResponse.argument.node);
                }
                oResponse.argument.fnLoadComplete();
            } catch (x) {
                alert("Error: "+x);
            }
        }.bind(this),
        failure: function(oResponse) {
            YAHOO.log("Failed to process XHR transaction.", "info", "example");
            oResponse.argument.fnLoadComplete();
        },
        argument: {
            "node": node,
            "fnLoadComplete": fnLoadComplete
        },
        timeout: 7000
    };

    YAHOO.util.Connect.asyncRequest('GET', sUrl, callback);
}

Backup.prototype.setupTable = function(user, folder, type) {
    if (typeof this.messagemenu !== "undefined") {
        this.messagemenu.destroy();
    }
    if (typeof this.table !== "undefined") {
        // TODO: destory table if it exists
        //this.table.destroy();
    }
    var myColumnDefs = [
            {
                key: "restorekey",
                label: "restorekey",
                sortable: true,
                hidden: true,
            }
    ];

    if (type === "IPF.Appointment") {
        myColumnDefs.push(
            {
                key: "subject",
                label: _("lbl_subject"),
                sortable: true
            }, {
                key: "start",
                label: _("lbl_start"),
                sortable: true
            }, {
                key: "end",
                label: _("lbl_end"),
                sortable: true
            }, {
                key: "date",
                label: _("lbl_date"),
                sortable: true,
            }
        );
    }
    else {
        myColumnDefs.push(
            {
                key: "subject",
                label: _("lbl_subject"),
                sortable: true
            }, {
                key: "sender",
                label: _("lbl_sender"),
                sortable: true
            }, {
                key: "date",
                label: _("lbl_date"),
                sortable: true,
            }
        );
    }

    var myCfg = {
        dynamicData: true,
        initialRequest: "sort=id&dir=asc&startIndex=0&results=15",
        sortedBy: {key: "date", dir:YAHOO.widget.DataTable.CLASS_DESC }
    };

    this.table = new Yaffas.Table({
            container: "mainpane",
            columns: myColumnDefs,
            url: "/zarafabackup/messages.cgi?day="+encodeURI(this.selectedDay)+"&user="+encodeURI(user)+"&id="+encodeURI(folder)+"&",
            selectionMode: "standard",
            config: myCfg,
            hideFilter: 1,
            sortColumn: -1
        });

    var i = [
        {
            text: _("lbl_restore"),
            onclick: {
                fn: this.addRestoreMessage.bind(this)
            }
        }
    ];


    this.messagemenu = new Yaffas.Menu({ container: "messagemenu", trigger: "mainpane", items: i, multiselect: true });
}

Backup.prototype.setupLayout = function() {
    this.tree = new YAHOO.widget.TreeView("folderpane");
    this.tree.render();

    this.tree.subscribe("labelClick", function(node) {
            var n = node;
            var r = this.tree.getRoot();

            while (n.parent) {
                if (n.parent === r) {
                    break;
                }
                n = n.parent;
            }
            this.selectedFolder = node;
            this.selectedStore = n;

            this.setupTable(n.label, node.data.id, node.data.type);
        }.bind(this)
    );

    this.setupFolderContextMenu();

    this.layout = new YAHOO.widget.Layout("backuplayout", {
            units: [
                { position: "top", height: "35px", body: "backupselectpane", scroll: false },
                { position: "left", width: "200px", body: "folderpane", resize: true },
                { position: "center", body: "mainpane" }
            ]
        });

    this.layout.render();

}

Backup.prototype.setupFolderContextMenu = function() {
    var i = [
        {
            text: _("lbl_restore"),
            onclick: {
                fn: this.addRestoreFolder.bind(this)
            }
        }
    ];

    this.foldermenu = new YAHOO.widget.ContextMenu("foldermenu", {
        trigger: "folderpane",
        lazyload: true,
        itemdata: i
    });

    function onTriggerContextMenu(p_oEvent) {
        var oTarget = this.contextEventTarget;
        module.currentFolderNode = module.tree.getNodeByElement(oTarget);

        if (!module.currentFolderNode) {
            module.cancel();
        }
    }

    this.foldermenu.subscribe("triggerContextMenu", onTriggerContextMenu);
    this.foldermenu.render(document.body);
}

Backup.prototype.setupUI = function() {
    this.setupLayout();
    this.fillBackupDates();
}

Backup.prototype.cleanup = function() {
    if (this.foldermenu) {
        this.foldermenu.destroy();
        this.foldermenu = null;
    }
	if (this.messagemenu) {
        this.messagemenu.destroy();
        this.messagemenu = null;
	}
	this.restore.cleanup();
}

Backup.prototype.savedForm = function(file) {
    switch(file) {
        case "settings.cgi":
            Yaffas.ui.reloadTabs();
    }
}

module = new Backup();
module.setupUI();
