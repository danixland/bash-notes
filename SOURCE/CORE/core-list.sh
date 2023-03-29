function listnotes() {
	# [ $PLAIN == true ] && echo "output is plain text" || echo "output is colored"
	if [[ $(ls -A "$NOTESDIR") ]]; then
		if [ $PLAIN == false ]; then
			echo "listing all notes"
			echo ""
		fi
		[ $PLAIN == false ] && echo "[ID]	[TITLE]		[CREATED]"
		for i in "${NOTESDIR}"/*; do
			# shellcheck disable=SC2155
			local fname=$(basename $i)
			DATE=$(date -d @${fname} +"%d/%m/%Y %R %z%Z")
			# shellcheck disable=SC2016,SC2086
			TITLE=$($JQ -r --arg z $(basename $i) '.notes[] | select(.file == $z) | .title' $DB)
			# shellcheck disable=SC2016,SC2086
			ID=$($JQ -r --arg z $(basename $i) '.notes[] | select(.file == $z) | .id' $DB)
			[ $PLAIN == false ] && echo "[${ID}]	${TITLE}	${DATE}" || echo "${ID} - ${TITLE} - ${DATE}"
		done
	else
		echo "no notes yet. You can add your first one with: ${BASENAME} -a \"your note title\""
	fi
}
