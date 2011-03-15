#!/bin/sh

# downloaded from http://www.seaglass.com/downloads/pfcat.sh

PATH=/usr/bin:/usr/sbin
QS="deferred active incoming maildrop hold"
QPATH=`postconf -h queue_directory`

if [ $# -ne 1 ]; then
        echo "Usage: pfcat <queue id>"
        exit 1
fi

if [ `whoami` != "root" ]; then
        echo "You must be root to view queue files."
        exit 1
fi

if [ ! -d $QPATH ]; then
        echo "Cannot locate queue directory $QPATH."
        exit 1
fi

for q in $QS
do
        FILE=`find $QPATH/$q -type f -name $1`
        if [ -n "$FILE" ]; then
                postcat $FILE
                exit 0
        fi
done

if [ -z $FILE ]; then
        echo "No such queue file $1"
        exit 1
fi
