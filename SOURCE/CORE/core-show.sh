function shownote() {
	NOTE=$1

	# shellcheck disable=SC2155
	local OK=$(check_noteID "$NOTE")
	if [ ! "$OK" ]; then
		echo "invalid note \"$NOTE\""
		echo "Use the note ID that you can fetch after listing your notes"
		exit 1
	fi

	FILE=$($JQ -r --arg i $OK '.notes[] | select(.id == $i) | .file' $DB)

	if [ "$FILE" ]; then
		$PAGER ${NOTESDIR}/${FILE}
	fi
}
