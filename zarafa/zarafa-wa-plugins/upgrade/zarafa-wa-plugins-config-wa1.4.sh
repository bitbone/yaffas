#!/bin/bash

CONFIG=/opt/yaffas/zarafa/webapp/plugins/passwd/config.inc.php

# Older default configs had a trailing new line, which breaks things since
# WebApp 1.4, so we have to remove it:
/usr/bin/perl -pe 'chomp if eof' -i "$CONFIG"

# we changed our internal configuration class in the plugin update for 1.4
# to avoid clashing with other plugins, so we have to update
# existing configs accordingly:
sed -re 's:class +Configuration( |\{|$):class PluginpasswdConfiguration\1:' -i "$CONFIG"
