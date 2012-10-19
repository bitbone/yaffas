function ZarafaLicense(){
    this.setupTable();
}

ZarafaLicense.prototype.setupTable = function() {
    var myColumnDefs = [
    {
        key: "id",
        label: "",
        sortable: false,
        hidden: true,
    }, {
        key: "type",
        label: "",
        sortable: false
    }, {
        key: "allowed",
        label: _("lbl_stores_allowed"),
        sortable: false
    }, {
        key: "used",
        label: _("lbl_stores_used"),
        sortable: false,
    }, {
        key: "avail",
        label: _("lbl_stores_avail"),
        sortable: false
    }];
    this.usertable = new Yaffas.Table({
        container: "table",
        columns: myColumnDefs,
        url: "/zarafalicence/users.cgi",
    });
}

ZarafaLicense.prototype.savedForm = function(url){
    Yaffas.ui.reloadTabs();
}

module = new ZarafaLicense();
