#!/bin/bash

# This script checks whether all supported themes contain all
# necessary images (screenshots) found in the other themes
#
# Usage: ./bin/find-missing-images.sh

declare -a REQUIRED_IMAGES=()
BASE="images"
declare -a LANGUAGES=(de en)
declare -a THEMES=(yaffas zarafa)
EXCLUDE="($BASE/en/bitkit/)"

filter_false_positives() {
	grep -vP "$EXCLUDE"
	return $?
}

for lang in ${LANGUAGES[@]}; do
	for theme in ${THEMES[@]}; do
		for image in $(find "$BASE/$lang/$theme" -name '*.png' 2>/dev/null); do
			REQUIRED_IMAGES[${#REQUIRED_IMAGES[@]}]=$(basename "$image")
		done
	done
done
for expected_image in ${REQUIRED_IMAGES[@]}; do
	for lang in ${LANGUAGES[@]}; do
		for theme in ${THEMES[@]}; do
			path="$BASE/$lang/$theme/$expected_image"
			[[ -f "$path" ]] && continue
			echo "$path"
		done
	done
done | sort -u | filter_false_positives
