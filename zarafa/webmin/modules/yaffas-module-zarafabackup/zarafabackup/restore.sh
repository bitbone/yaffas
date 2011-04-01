#!/bin/bash

export PERLLIB=/opt/yaffas/lib/perl5/

INPUT=$1
DATE=$(date)
LOG="/var/log/zarafa-backup/restore.log"
TMPLOG="/var/log/zarafa-backup/tmp.restore.log"

[ ! -d "/var/log/zarafa-backup" ] && mkdir -p "/var/log/zarafa-backup";

perl -MJSON -MYaffas::Module::ZarafaBackup -we 'my $i = <STDIN>; my $a = from_json($i); Yaffas::Module::ZarafaBackup::restore($a);' < $INPUT > $TMPLOG

rm $INPUT

echo "Started at $DATE" >> $LOG
cat $TMPLOG >> $LOG
