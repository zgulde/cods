##############################################################################
# Script that provides tab completion for the ./server command
#
# Note that if any new subcommands are added, or existing ones are renamed, this
# file will need to be updated so that the tab completion is up to date
##############################################################################

SERVER_SUBCOMMANDS='site db devserver login upload restart reboot info adduser addkey autorenew tomcatlog followlog ping'
DB_SUBCOMMANDS='create backup run remove rm list ls login'
SITE_SUBCOMMANDS='list ls create remove rm build enablessl info deploy'

_server() {
	local cur prev opts

	COMPREPLY=()

	cur="${COMP_WORDS[COMP_CWORD]}"
	prev="${COMP_WORDS[COMP_CWORD-1]}"

	case $prev in
		*server) opts=$SERVER_SUBCOMMANDS;;
		db) opts=$DB_SUBCOMMANDS;;
		site) opts=$SITE_SUBCOMMANDS;;
	esac

	COMPREPLY=( $(compgen -W "$opts" -- $cur) )
}

complete -F _server ./server
