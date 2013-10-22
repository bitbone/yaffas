#!/bin/bash
/usr/bin/perl -pe 'chomp if eof' \
		-i /opt/yaffas/zarafa/webapp/plugins/passwd/config.inc.php
