#!/bin/bash

BASEDIR=/var/spool/postfix/dev

# is this a system which may be affected by this bug (i.e. Debian-based)?
[[ -d "$BASEDIR" ]] || exit 0

for node in random urandom; do
	[[ -f "$BASEDIR/$node" ]] || cp -a /dev/"$node" "$BASEDIR/$node"
done
