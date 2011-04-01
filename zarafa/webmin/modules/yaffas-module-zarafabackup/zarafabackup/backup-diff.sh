#!/bin/bash

export PERLLIB=/opt/yaffas/lib/perl5/

DATE=$(date)
LOG="/var/log/zarafa-backup/backup.log"
TMPLOG="/var/log/zarafa-backup/tmp.backup.log"

[ ! -d "/var/log/zarafa-backup" ] && mkdir -p "/var/log/zarafa-backup";

perl -MJSON -MYaffas::Module::ZarafaBackup -we 'Yaffas::Module::ZarafaBackup::run("diff")' > $TMPLOG

echo "Started at $DATE" >> $LOG
cat $TMPLOG >> $LOG
