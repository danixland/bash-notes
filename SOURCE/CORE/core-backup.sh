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
    	BCKUP_COMM=$(rsync -avz --progress ${RCFILE} ${BASEDIR}/* ${BACKUPDIR})
    else
    	BCKUP_COMM=$(rsync -avz --progress ${BASEDIR}/* ${BACKUPDIR})
    fi
    # run the command
    if [ "$BCKUP_COMM" ]; then	
	    echo -e "BASE directory:\t\t$BASEDIR"
	    echo -e "BACKUP directory:\t$BACKUPDIR"
	    echo; echo "BACKUP COMPLETED"
	fi
}

function backup_restore() {
	echo "restoring backup"
}

