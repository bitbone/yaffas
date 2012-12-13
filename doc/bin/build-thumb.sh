#/bin/bash
INFILE="$1"
OUTFILE="${INFILE/.png/_thumb.png}"
SIZE="50%x50%"

if [[ ${INFILE} != ${INFILE/_thumb.png} ]]; then
	exit 1
fi
if [[ $(stat --format=%Y "${INFILE}" 2>/dev/null || echo 0) \
		-lt $(stat --format=%Y "${OUTFILE}" 2>/dev/null || echo 0) ]]; then
	exit 0
fi
echo "Building thumb of $INFILE"
convert "${INFILE}" -resize "${SIZE}" "${OUTFILE}"
exit $?
