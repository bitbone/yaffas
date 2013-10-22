<?php
  if (!defined("PLUGIN_PASSWD_USER_DEFAULT_ENABLE")) {
    // this will usually by defined in config.inc.php, but
    // users who installed with previous versions may not
    // have it
    define("PLUGIN_PASSWD_USER_DEFAULT_ENABLE", true);
  }
  /**
   * Passwd Plugin
   * Integrates (AD) password changing functionality
   * based on http://doc.zarafa.com/trunk/WebApp_Developers_Manual/en-US/html-single/#settings_model
   */
  class Pluginpasswd extends Plugin {

    /**
     * Function initializes the Plugin and registers all hooks
     * @return void
     */
    function init() {
      $this->registerHook('server.core.settings.init.before');
    }

    /**
     * Function is executed when a hook is triggered by the PluginManager
     * @param string $eventID the id of the triggered hook
     * @param mixed $data object(s) related to the hook
     * @return void
     */
    function execute($eventID, &$data) {
      switch($eventID) {
        case 'server.core.settings.init.before' :
          $this->injectPluginSettings($data);
          break;
      }
    }

    /**
     * Called when the core Settings class is initialized and ready to accept
     * the sysadmin's default settings. Registers the sysadmin defaults
     * for the plugin.
     * @param Array $data Reference to the data of the triggered hook
     */
    function injectPluginSettings(&$data) {
      $data['settingsObj']->addSysAdminDefaults(Array(
        'zarafa' => Array(
          'v1' => Array(
            'plugins' => Array(
              'passwd' => Array(
                'enable' => PLUGIN_PASSWD_USER_DEFAULT_ENABLE,
              )
            )
          )
        )
      ));
    }
  }
  /*
     vim:ts=2:sw=2:et:
  */
?>
