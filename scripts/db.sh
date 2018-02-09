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
	while getopts 'n:u:' opt ; do
		case $opt in
			d) db_name=${OPTARG};;
			u) db_user=${OPTARG};;
		esac
	done
	if [[ -z $db_name ]] || [[ -z $db_user ]] ; then
		echo 'Create a database and user that has permissions only on that database'
		echo 'You will be prompted to choose a password for the new database user,'
		echo 'this should be an alphanumeric password.'
		echo
		echo '-d <db name>'
		echo '-u <db user>'
		echo
		echo 'Example:'
		echo "    $(basename $0) db create -d example_db -u example_user"
		die
	fi

	if [[ "$db_pass" != "$confirm_pass" ]]; then
		echo 'ERROR: passwords do not match!'
		exit 1
	fi

	cat <<-message
	creating database:
	    database: $db_name
	    user:     $db_user

	When prompted, enter your *database administrator* password to continue
	message

	ssh -t $user@$ip "mysql -p <<sql
	CREATE DATABASE IF NOT EXISTS $db_name;
	CREATE USER IF NOT EXISTS '$db_user'@'localhost' IDENTIFIED BY '$db_pass';
	GRANT ALL ON ${db_name}.* TO '$db_user'@'localhost';
	FLUSH PRIVILEGES;
sql"

	[[ $? -eq 0 ]] && echo 'Database Created!'
}

backup_db() {
	while getopts 'd:f:' opt ; do
		case $opt in
			d) database=${OPTARG};;
			f) outputfile=${OPTARG};;
		esac
	done
	if [[ -z $database ]]; then
		echo 'Create a backup of a database. Optionally specify a filename to save'
		echo 'the backup to. Will default to a file with the current time and the database'
		echo 'name inside of "db-backups"'
		echo
		echo '-d <database>'
		echo '-f <outputfile> (optional)'
		echo
		echo 'Examples:'
		echo "    $(basename $0) db backup -d example_db"
		echo "    $(basename $0) db backup -d example_db -f ~/my-db-dump.sql"
		die
	fi
	if [[ -z $outputfile ]]; then
		outputfile="$BASE_DIR/db-backups/$(date +%Y-%m-%d_%H:%M:%S)-${database}-backup.sql"
	fi

	read -sp 'Database Password: ' db_pass
	echo -e "\nbacking up...."
	ssh -t $user@$ip "mysqldump -p${db_pass} ${database} 2>/dev/null" > $outputfile
	echo
	echo "$outputfile created!"
}

remove_db() {
	while getopts 'd:u:' opt ; do
		case $opt in
			d) db_name=${OPTARG};;
			u) db_user=${OPTARG};;
		esac
	done
	if [[ -z $db_name ]] || [[ -z $db_user ]] ; then
		echo 'Remove a database and database user'
		echo
		echo '-d <database>'
		echo '-u <username>'
		echo
		echo 'Example:'
		echo "    $(basename $0) db remove -d example_db -u example_user"
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

	    $(basename $0) db <command> [options]

	where <command> is one of the following:

	    login
	    list
	    create -d <dbname> -u <user>
	    remove -d <dbname> -u <user>
	    backup -d <dbname> [-f <outputfile>]

	help_message
}

command=$1
shift

case $command in
	create)    create_db $@;;
	backup)    backup_db $@;;
	remove|rm) remove_db $@;;
	list|ls)   list_databases;;
	login)     login;;
	*)         show_usage;;
esac
