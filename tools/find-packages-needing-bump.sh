#!/bin/bash
# Searches for debian packages whose last changelog update is older than
# the most recent update to the package's directory (i.e. code or
# build instructions)
BASEDIR=$(readlink -f $(dirname "$0")/..)

getLatestChange() {
		git log --max-count 1 --format=%at "$1"
}

echo "# The following changelogs need to be updated as"
echo "# the package has been changed after the last changelog"
echo "# update."
echo

for changelogPath in $(find "$BASEDIR" -name changelog); do
		changelogDate=$(getLatestChange "$changelogPath")
		packageDir=$(dirname "$changelogPath")"/.."
		packageDate=$(getLatestChange "$packageDir")
		[[ $changelogDate -ge $packageDate ]] && continue
		# ignore, if there are any local changes:
		[[ $(git status --porcelain "$changelogPath") ]] && continue
		echo $changelogPath
done
