#!/bin/bash

LOGFILE=/root/yaffas-upgrade.log
if [ -e $LOGFILE ]; then
	mv $LOGFILE ${LOGFILE}.old
fi

echo "Starting upgrade procedures ..." >> $LOGFILE

for UPGRADE in /opt/yaffas/share/yaffas-upgrade/*.sh; do
	echo $(basename $UPGRADE) >> $LOGFILE
	bash "$UPGRADE" >> $LOGFILE
done

echo "... done" >> $LOGFILE
