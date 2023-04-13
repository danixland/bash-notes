# shellcheck disable=SC2006
GOPT=$(getopt -o hvplr::a::e::d::s:: --long help,version,list,plain,userconf,sync,restore::,backup::,add::,edit::,delete::,show:: -n 'bash-notes' -- "$@")

# shellcheck disable=SC2181
if [ $? != 0 ] ; then helptext >&2 ; exit 1 ; fi

# Note the quotes around `$GOPT': they are essential!
eval set -- "$GOPT"
unset GOPT

while true; do
	case "$1" in
	  	-h | --help )
			helptext
	        exit
	        ;;
		-v | --version )
			echo $BASENAME v${VERSION}
			exit
			;;
	    -p | --plain )
			PLAIN=true
			shift
	        ;;
	    -l | --list )
			listnotes
			exit
	        ;;
	    -a | --add )
			case "$2" in
				'' )
					read -r -p "Title: " TITLE
					;;
				* )
					TITLE=$2
					;;
			esac
			shift 2
			addnote "$TITLE"
			exit
	        ;;
		-e | --edit )
			case "$2" in
				'' )
					read -r -p "Note ID: " NOTE
					;;
				* )
					NOTE=$2
					;;
			esac
			shift 2
			editnote "$NOTE"
			exit
			;;
		-d | --delete )
			case "$2" in
				'' )
					read -r -p "Note ID: " NOTE
					;;
				* )
					NOTE=$2
					;;
			esac
			shift 2
			rmnote "$NOTE"
			exit
			;;
		-s | --show )
			case "$2" in
				'' )
					read -r -p "Note ID: " NOTE
					;;
				* )
					NOTE=$2
					;;
			esac
			shift 2
			shownote "$NOTE"
			exit
			;;
		-r | --restore )
			case "$2" in
				'' )
					read -r -p "Backup Dir: " RDIR
					;;
				* )
					RDIR=$2
					;;
			esac
			shift 2
			backup_restore $RDIR
			exit
			;;
		--sync )
			gitsync
			exit
			;;
		--userconf )
			export_config
			# shellcheck disable=SC2317
			echo "config exported to \"$RCFILE\""
			# shellcheck disable=SC2317
			exit
			;;
		--backup )
			case "$2" in
				'' )
					read -r -p "Backup Dir: " BDIR
					;;
				* )
					BDIR=$2
					;;
			esac
			shift 2
			backup_data $BDIR
			exit
			;;
		-- )
			shift
			break
			;;
		* )
			break
			;;
	esac
done

for arg; do
	if [ $(check_noteID $arg) ]; then
		shownote $arg
	else
		helptext
		exit
	fi
done
