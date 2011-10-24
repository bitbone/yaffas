#!/bin/bash

if [ ! -f module.info ]; then
	echo "File module.info not found."
	exit 0
fi

for l in "de" "nl" "fr" "pt_BR"; do
	title=$(awk -F= '/^moduletitle/ { print "desc_" "'$l'" "=" $2 }' lang/$l)

	if [ -z "$title" ]; then
		title=$(awk -F= '/^moduletitle/ { print "desc_" "'$l'" "=" $2 }' lang/en)
	fi


	if grep -q "desc_$l=" module.info; then
		sed -e "s/desc_$l=.*/$title/" -i module.info
	else
		echo $title >> module.info
	fi
done
