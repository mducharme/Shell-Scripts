#!bin/sh
#
# backup_svn.sh
#
# Backup all SVN repositories in a given directory
# Keep a log of all versions and only do incremental backup
#
# Back up to a target directory and to a FTP server (with curl)
#
# This script should be called automatically from a cron
#
# @copyright (c) Locomotive 2013
# @author Mathieu Ducharme <mat@locomotive.ca>
# @version 2013-08-19
# @since Version 2013-08-19
# @license (c) Locomotive 2013
#
# @todo A --repo switch to only backup one single repository
# @todo A --force-reload switch to re-backup everything from version 0 (Make sure this cleans old backup files...)
# @todo Create the required repos and versions subdirectories in the backup path if necessary
# @todo Only backup to FTP if the variables are set properly
# @todo Cloud (S3) backup

# Source directory containing the SVN repositories to backup
SVN_PATH="/home/locosvn/repos";
# SVN server URL containing the same repositories. Used to check svn version
SVN_URL="file:///home/locosvn/repos";
# Target dierctory where the backup will be sent. Need "repos" and "versions" subdirectories.
BACKUP_PATH="/backup/SVN";

# FTP Information
FTP_SERVER="ftp://locomotive.no-ip.biz";
FTP_PATH="Backups/SVN/";
FTP_USER="FTP_USER";
FTP_PASSWORD="FTP_PASSWORD";

for SVN_REPO in `ls -1 $SVN_PATH`;
do
	CURRENT_VERSION=`svn info $SVN_URL/$SVN_REPO | grep Revision | awk '{print $2}'`
	LAST_VERSION=`cat $BACKUP_PATH/versions/$SVN_REPO 2>/dev/null`	
	
	if [ "$LAST_VERSION" = "" ]
	then
		echo "Doing full backup of $SVN_REPO (v.$CURRENT_VERSION)";
	    svnadmin dump -q $SVN_PATH/$SVN_REPO > $BACKUP_PATH/repos/$SVN_REPO.0-$CURRENT_VERSION.dump;
	    # @todo: Only do FTP
		curl -T $BACKUP_PATH/repos/$SVN_REPO.0-$CURRENT_VERSION.dump $FTP_SERVER/$FTP_PATH --user $FTP_USER:$FTP_PASSWORD;	    
	    echo $CURRENT_VERSION > $BACKUP_PATH/versions/$SVN_REPO;
	else
		if [ "$LAST_VERSION" == "$CURRENT_VERSION" ]
	    then
	    	echo "Backup for $SVN_REPO is not necessary";
	    else
	    	echo "Doing incremental backup ($LAST_VERSION => $CURRENT_VERSION) of $SVN_REPO";
	        svnadmin dump -q $SVN_PATH/$SVN_REPO -r$LAST_VERSION:$CURRENT_VERSION --incremental  > $BACKUP_PATH/repos/$SVN_REPO.$LAST_VERSION-$CURRENT_VERSION.dump;
			curl -T $BACKUP_PATH/repos/$SVN_REPO.$LAST_VERSION-$CURRENT_VERSION.dump $FTP_SERVER/$FTP_PATH --user $FTP_USER:$FTP_PASSWORD;
	        echo $CURRENT_VERSION > $BACKUP_PATH/versions/$SVN_REPO;
	    fi
	fi
done;

