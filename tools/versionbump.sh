#!/bin/bash
error() {
		echo "$@"
		exit 1
}

have_uncommitted_changes() {
		[[ -n $(git status -s) ]]
}

VERSION=$1
[[ $VERSION ]] || error "Syntax: $(basename "$0") 1.2.3-4"
have_uncommitted_changes && \
		error "Please commit/stash all your local changes first"
BASEDIR="$(dirname "$0")"
find -path '*/debian/changelog' | \
		grep -vP 'ckeditor|z-push' | \
		xargs -I '{}' "$BASEDIR/"updatechangelog.sh {} -v $VERSION "update to version $VERSION"
