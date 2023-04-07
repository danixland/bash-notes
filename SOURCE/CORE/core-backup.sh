function backup_data() {
	BACKUPDIR="$1"
    echo "backing up data in $BACKUPDIR"


    if [ -d $BACKUPDIR ]; then
    	if [ $(/bin/ls -A $BACKUPDIR) ]; then
	    	echo "$BACKUPDIR is not empty. Cannot continue"
	    	exit
	    else
	    	echo "$BACKUPDIR is ok. Continuing!"
	    fi
	else
		# BACKUPDIR doesn't exists
		echo "$BACKUPDIR doesn't exists"
		read -r -p "Do you want me to create it for you? (y/N) " ANSWER
		case $ANSWER in
			y|Y )
				mkdir -p $BACKUPDIR
				;;
			* )
				echo "No changes made. Exiting"
				exit
				;;
		esac
    fi
    # ok, we have a backup directory
    if [ -r $RCFILE ]; then
    	BCKUP_COMM=$(rsync -avz --progress ${RCFILE}* ${BASEDIR}/* ${BACKUPDIR})
    else
    	BCKUP_COMM=$(rsync -avz --progress ${BASEDIR}/* ${BACKUPDIR})
    fi
    # run the command
    if [ "$BCKUP_COMM" ]; then	
	    echo -e "All files backed up."
	    echo -e "BACKUP directory:\t$BACKUPDIR"
	    tree $BACKUPDIR | $PAGER
	    echo; echo "BACKUP COMPLETED"
	fi
}

function backup_restore() {
	BACKUPDIR="$1"
	echo "restoring backup from $BACKUPDIR"
	echo "This will overwrite all your notes and configurations with the backup."
	read -r -p "Do you want to continue? (y/N) " ANSWER
	case $ANSWER in
		y|Y )
			# restoring rc file
			BACKUPRC=$(basename $RCFILE)
			if [ -r ${BACKUPDIR}/${BACKUPRC} ]; then
				if [ -r ${RCFILE} ]; then
					echo "Backing up current '${RCFILE}'...."
					mv -f ${RCFILE} ${RCFILE}.$(date +%Y%m%d_%H%M)
				fi
				cp --verbose ${BACKUPDIR}/${BACKUPRC} $RCFILE
			fi
			# restoring notes directory
			if [ -d $BACKUPDIR/notes ]; then
				if [ $(/bin/ls -A $NOTESDIR) ]; then
					rm --verbose $NOTESDIR/*
				fi
				cp -r --verbose $BACKUPDIR/notes $BASEDIR
			fi
			# restoring database
			BACKUPDB=$(basename $DB)
			if [ -f ${BACKUPDIR}/${BACKUPDB} ]; then
				if [ -r ${DB} ]; then
					echo "Backing up current '${DB}'...."
					mv -f ${DB} ${DB}.$(date +%Y%m%d_%H%M)
				fi
				cp --verbose ${BACKUPDIR}/${BACKUPDB} $DB
			fi
			;;
		* )
			echo "No changes made. Exiting"
			exit
			;;
	esac
}

