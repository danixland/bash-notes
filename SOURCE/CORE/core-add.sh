addnote() {
	# attempt syncing before adding a note
	gitsync -f
	# remove eventually existing temp DB file
	if [[ -f $TMPDB ]]; then
		rm $TMPDB
	fi

	RTITLE=$(random_title)
	[[ -z "$1" ]] && NOTETITLE="$RTITLE" || NOTETITLE="$1"
	echo "adding new note - \"$NOTETITLE\""
	# shellcheck disable=SC2086
	LASTID=$($JQ '.notes[-1].id // 0 | tonumber' $DB)
	# [ "" == $LASTID ] && LASTID=0
	NOTEID=$(( LASTID + 1 ))
	# shellcheck disable=SC2086
	touch ${NOTESDIR}/${NOW}
	# shellcheck disable=SC2016
	$JQ --arg i "$NOTEID" --arg t "$NOTETITLE" --arg f "$NOW" '.notes += [{"id": $i, "title": $t, "file": $f}]' "$DB" > $TMPDB
	# shellcheck disable=SC2086
	mv $TMPDB $DB
	# example for alacritty:
	# alacritty --class notes --title notes -e /usr/bin/vim ...
	# shellcheck disable=SC2086,SC2091
	$(${TERMINAL} ${TERM_OPTS} ${EDITOR} ${NOTESDIR}/${NOW})
	# add note to git and push to remote
	gitadd
}
