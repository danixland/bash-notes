all: notes.sh

notes.sh: SOURCE/head.sh SOURCE/CORE/helpers.sh SOURCE/CORE/git.sh SOURCE/CORE/core-* SOURCE/main.sh
	cat $^ > "$@" || (rm -f "$@"; exit 1)
	chmod 755 "$@"
