Ext.namespace('Zarafa.plugins.passwdplugin');

Zarafa.plugins.passwdplugin.PasswdPluginSettingsCategory = Ext.extend(Zarafa.settings.ui.SettingsCategory, {

    /**
    * @constructor
    * @param {Object} config Configuration object
    */
    constructor : function(config) {
        config = config || {};

        Ext.applyIf(config, {
            title : _('Change Password'),
            iconCls : 'icon_exampleplugin_icon',
            items : [{
                xtype : 'zarafa.passwdsettingspluginwidget'
            }]
        });

        Zarafa.plugins.passwdplugin.PasswdPluginSettingsCategory.superclass.constructor.call(this, config);
    }
});

Ext.reg('zarafa.passwdpluginsettingscategory', Zarafa.plugins.passwdplugin.PasswdPluginSettingsCategory);

Zarafa.plugins.passwdplugin.PasswdPluginSettingsWidget = Ext.extend(Zarafa.settings.ui.SettingsWidget, {

    /**
    * @constructor
    * @param {Object} config Configuration object
    */
    constructor : function(config) {
        config = config || {};

        Ext.applyIf(config, {
            title : _('Change password'),
            layout : 'form',
            items : [{
                xtype:'fieldset',
                title: _('Insert a new password; at least 6 chars...'),
                flex : 1,
                border: false,
                items :[{
                    xtype : 'textfield',
                    ref : '../oldPassword',
                    inputType: 'password',
                    fieldLabel : _('Old password'),
                },{
                    xtype : 'textfield',
                    ref : '../newPassword',
                    inputType: 'password',
                    fieldLabel : _('New password'),
                },{
                    xtype : 'textfield',
                    inputType: 'password',
                    ref : '../newPasswordRepeat',
                    fieldLabel : _('New password (repeat)'),
                }]
            }]

        });
        Zarafa.plugins.passwdplugin.PasswdPluginSettingsWidget.superclass.constructor.call(this, config);
    },

    handlePasswordChanged: function(res) {
        var t = res.responseText;
        var obj;
        try {
            obj = Ext.decode(t);
        }
        catch(e) {
            obj.status = "failure";
            obj.message = _("Unknown response");
        }
        var msg = _(obj.message);
        var title = "";

        if (obj.status === "success") {
            title = _("Password changed");
        }
        else {
            title = _("Error");
        }

        Ext.MessageBox.show({
            "title": title,
            "msg": msg,
            buttons: Ext.MessageBox.OK,
            fn: function() {
                if (obj.status === "success") {
                    container.logout();
                }
            }
        });
    },

    /**
    * Called by the {@link Zarafa.settings.ui.SettingsCategory Category} when
    * it has been called with {@link zarafa.settings.ui.SettingsCategory#updateSettings}.
    * This is used to update the settings from the UI into the {@link Zarafa.settings.SettingsModel settings model}.
    * @param {Zarafa.settings.SettingsModel} settingsModel The settings to update
    */
    updateSettings : function(settingsModel)
    {
        this.newPassword.getValue();
        this.oldPassword.getValue();
        console.log("updateSettings");

        // Basic request
        Ext.Ajax.request({
            url: 'plugins/passwd/php/pwdchange.php',
            success: this.handlePasswordChanged,
            failure: function() {console.log("failure")},
            params: { pwdchange_newpwd1: this.newPassword.getValue(),
                pwdchange_oldpw: this.oldPassword.getValue(),
                pwdchange_newpwd2: this.newPasswordRepeat.getValue(),
                pwdchange_username: container.getUser().getUserName(),
            }
        });


    },
});

Ext.reg('zarafa.passwdsettingspluginwidget', Zarafa.plugins.passwdplugin.PasswdPluginSettingsWidget);

Zarafa.plugins.passwdplugin.PasswdPlugin = Ext.extend(Zarafa.core.Plugin, {
    constructor : function(config) {

        Zarafa.plugins.passwdplugin.PasswdPlugin.superclass.constructor.call(this, config);
        this.init();

    },

    init : function() {
        this.registerInsertionPoint('context.settings.categories', this.putSettingCategory, this);
    },

    /**
    * Return the instance of {@link Zarafa.plugins.passwdplugin.PasswdPluginSettingsCategory}.
    */
    putSettingCategory : function()
    {
        return {
            xtype : 'zarafa.passwdpluginsettingscategory',
        }
    },
});


Zarafa.onReady(function() {
    container.registerPlugin(new Zarafa.plugins.passwdplugin.PasswdPlugin());
});

