##############################################################################
# Database management script
#
# This script contains functions for database management, and will invoke the
# appropriate function based on the arguments passed to it.
##############################################################################

list_databases() {
	ssh -t $user@$ip "mysql -p -e 'show databases'"
}

list_users() {
	ssh -t $user@$ip "mysql -p -e 'select user from mysql.user'"
}

create_db() {
	while [[ $# -gt 0 ]] ; do
	    arg=$1 ; shift
	    case $arg in
	        -n|--name) dbname=$1 ; shift;;
	        --name=*) dbname=${arg#*=};;
			-u|--user) dbuser=$1 ; shift;;
			--user=*) dbuser=${arg#*=};;
	        *) echo "Unknown argument: $arg" ; exit 1;;
	    esac
	done
	if [[ -z $dbname ]] || [[ -z $dbuser ]] ; then
		cat <<-.
		Create a database and user that has permissions only on that database.
		A random password will be generated for the new user and stored in
		$DATA_DIR/credentials.txt

		-n|--name <dbname> -- name of the database to create
		-u|--user <dbuser> -- name of the database user to create

		Examples:
		    $(basename "$0") db create -n example_db -u example_user
		    $(basename "$0") db create --name=test_db --user=test_user
		.
		die
	fi

	db_pass="$(mkpassword)"

	cat <<-.
	- Creating Database:

	    database: $dbname
	    user:     $dbuser

	  When prompted, enter your *database administrator* password to continue
	.

	ssh -t $user@$ip "mysql -p <<sql
	CREATE DATABASE $dbname;
	CREATE USER IF NOT EXISTS '$dbuser'@'localhost' IDENTIFIED BY '$db_pass';
	GRANT ALL ON ${dbname}.* TO '$dbuser'@'localhost';
	FLUSH PRIVILEGES;
sql"
	if [[ $? -eq 0 ]] ; then
		echo "Db User $dbuser: $db_pass" >> "$DATA_DIR/credentials.txt"
		cat <<-.
		- User Successfully Created!
		  password for $dbuser: $db_pass
		  [NOTICE] credentials for $dbuser have been added to the credentials file
		           $DATA_DIR/credentials.txt
		.
	else
		echo 'Uh oh, looks like something went wrong. Check the output above and'
		echo 'try again.'
	fi
}

backup_db() {
	while [[ $# -gt 0 ]] ; do
	    arg=$1 ; shift
	    case $arg in
	        -n|--name) database=$1 ; shift;;
	        --name=*) database=${arg#*=};;
			-o|--outfile) outputfile="$1" ; shift;;
			--outfile=*) outputfile="${arg#*=}" ; outputfile="${outputfile/#\~/$HOME}";;
	        *) echo "Unknown argument: $arg" ; exit 1;;
	    esac
	done
	if [[ -z $database ]]; then
		cat <<-.
		Create a backup of a database. Optionally specify a filename to save the
		backup to. Will default to a file with the current time and the database
		name inside of $DATA_DIR/db-backups

		-n|--name    <dbname>     -- name of the database to backup
		-o|--outfile <outputfile> -- (optional) where to save the sql dump

		Examples:
		    $(basename "$0") db backup -n example_db
		    $(basename "$0") db backup -n example_db -o ~/my-db-dump.sql
		    $(basename "$0") db backup --name=blog_db --outfile=./src/main/sql/blog-backup.sql
		.
		die
	fi
	if [[ -z "$outputfile" ]]; then
		outputfile="$DATA_DIR/db-backups/$(date +%Y-%m-%d_%H:%M:%S)-${database}-backup.sql"
	fi

	read -sp 'Database Password: ' db_pass
	echo -e "\nbacking up...."
	ssh -t $user@$ip "mysqldump -p${db_pass} ${database} 2>/dev/null" > "$outputfile"
	echo
	echo "$outputfile created!"
}

remove_db() {
	while [[ $# -gt 0 ]] ; do
	    arg=$1 ; shift
	    case $arg in
	        -n|--name) db_name=$1 ; shift;;
	        --name=*) db_name=${arg#*=};;
			-u|--user) db_user=$1 ; shift;;
			--user=*) db_user=${arg#*=};;
	        *) echo "Unknown argument: $arg" ; exit 1;;
	    esac
	done
	if [[ -z $db_name ]] || [[ -z $db_user ]] ; then
		cat <<-.
		Remove a database and database user

		-n|--name <dbname> -- name of the database to remove
		-u|--user <dbuser> -- name of the user to remove

		Examples:
		    $(basename "$0") db remove -n example_db -u example_user
		    $(basename "$0") db remove --name test_db --user test_user
		.
		die
	fi

	ssh -t $user@$ip "mysql -p -e 'DROP DATABASE ${db_name}'
					  mysql -p -e 'DROP USER ${db_user}@localhost'"
	[[ $? -eq 0 ]] && echo 'Database Removed!'
}

login() {
	ssh -t $user@$ip mysql -p
}

show_usage() {
	cat <<-help_message
	db -- command for interacting with databases on your server
	usage

	    $(basename "$0") db <command> [options]

	where <command> is one of the following:

	    login
	    list
	    create -n <dbname> -u <user>
	    remove -n <dbname> -u <user>
	    backup -n <dbname> [-o <outputfile>]

	help_message
}

command=$1
shift

case $command in
	create)    create_db "$@";;
	backup)    backup_db "$@";;
	remove|rm) remove_db "$@";;
	list|ls)   list_databases;;
	login)     login;;
	*)         show_usage;;
esac
