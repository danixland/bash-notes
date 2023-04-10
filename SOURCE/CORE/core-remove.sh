function rmnote() {
	# remove eventually existing temp DB file
	if [[ -f $TMPDB ]]; then
		rm $TMPDB
	fi

	NOTE=$1
	if [ "all" == "$NOTE" ]; then
		echo "You're going to delete all notes."
		read -r -p "Do you wish to continue? (y/N) " ANSWER
		case $ANSWER in
			y|Y )
				# shellcheck disable=SC2086
				$JQ 'del(.notes[])' $DB > $TMPDB
				# shellcheck disable=SC2086
				mv $TMPDB $DB
				# shellcheck disable=SC2086
				rm $NOTESDIR/*
				echo "Deleted all notes"
				;;
			* )
				echo "Aborting, no notes were deleted."
				exit 1
				;;
		esac
	else
		# shellcheck disable=SC2155
		local OK=$(check_noteID "$NOTE")
		if [ ! "$OK" ]; then
			echo "invalid note \"$NOTE\""
			echo "Use the note ID that you can fetch after listing your notes"
			sleep 1
			exit 1
		fi

		# shellcheck disable=SC2016,SC2086
		TITLE=$($JQ --arg i $OK '.notes[] | select(.id == $i) | .title' $DB)
		# shellcheck disable=SC2016,SC2086
		FILE=$($JQ -r --arg i $OK '.notes[] | select(.id == $i) | .file' $DB)
		if [ "$TITLE" ]; then
			# shellcheck disable=SC2016,SC2086
			$JQ -r --arg i $OK 'del(.notes[] | select(.id == $i))' $DB > $TMPDB
			# shellcheck disable=SC2086
			mv $TMPDB $DB
			rm $NOTESDIR/$FILE
			echo "Deleted note $TITLE"
			sleep 1
			exit
		else
			 echo "note not found"
			 sleep 1
			 exit 1
		fi
	fi
}
