#!/bin/bash
VERSION=$1
BASEDIR="$(dirname $0)"
find -path '*/debian/changelog' | \
		grep -vP 'ckeditor|z-push' | \
		xargs -I '{}' "$BASEDIR/"updatechangelog.sh {} -v $VERSION "update to version $VERSION"
