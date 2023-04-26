# shellcheck disable=SC2006
GOPT=$(getopt -o hvplr:a:e:d:s: --long help,version,list,plain,userconf,showconf,sync,restore:,backup:,add:,edit:,delete:,show: -n 'bash-notes' -- "$@")

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
			TITLE=$2
			shift 2
			addnote "$TITLE"
			exit
	        ;;
		-e | --edit )
			NOTE=$2
			shift 2
			editnote "$NOTE"
			exit
			;;
		-d | --delete )
			NOTE=$2
			shift 2
			rmnote "$NOTE"
			exit
			;;
		-s | --show )
			NOTE=$2
			shift 2
			shownote "$NOTE"
			exit
			;;
		-r | --restore )
			RDIR=$2
			shift 2
			backup_restore $RDIR
			exit
			;;
		--sync )
			# I'm forcing it because if you run it manually, chances are that you need to.
			gitsync -f
			shift
			exit
			;;
		--userconf )
			export_config
			# shellcheck disable=SC2317
			echo "config exported to \"$RCFILE\""
			# shellcheck disable=SC2317
			exit
			;;
		--showconf )
			configtext
			exit
			;;
		--backup )
			BDIR=$2
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
