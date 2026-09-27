#! /bin/bash

# bash-notes © 2023 by danix is licensed under CC BY-NC 4.0.
# To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/4.0/

# rofi front end for notes.sh. Bind it to hotkeys in your window manager:
#   rofi-notes.sh       show note
#   rofi-notes.sh -a    add note
#   rofi-notes.sh -e    edit note
#   rofi-notes.sh -d    delete note

rofi_command="rofi -theme ~/.config/rofi/udt/menu.rasi"
notes_command=notes

# list of existing notes passed to rofi
options=$($notes_command -pl)

# how to run the script
PARAM="$1"
case $PARAM in
	-a )
		# add note
		kitty --session=none --class notes -T notes $notes_command -a
		;;
	-e )
		# edit note_ID
		selected=$(echo -e "$options" | $rofi_command -p "edit note" -dmenu -selected-row 0 | cut -d " " -f1)
		[ -n "$selected" ] || exit 0
		kitty --session=none --class notes -T notes $notes_command -e ${selected}
		;;
	-d )
		# delete note_ID
		selected=$(echo -e "$options" | $rofi_command -p "delete note" -dmenu -selected-row 0 | cut -d " " -f1)
		[ -n "$selected" ] || exit 0
		kitty --session=none --class notes -T notes $notes_command -d ${selected}
		;;
	* )
		# list notes
		selected=$(echo -e "$options" | $rofi_command -p "notes" -dmenu -selected-row 0 | cut -d " " -f1)
		[ -n "$selected" ] || exit 0
		kitty --session=none --class notes -T notes $notes_command -s $selected
		;;
esac
