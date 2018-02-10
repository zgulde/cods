SERVER_SUBCOMMANDS='site db devserver login upload restart reboot info adduser addkey autorenew log:tail log:cat ping credentials bash-completion'
DB_SUBCOMMANDS='create backup run remove rm list ls login'
SITE_SUBCOMMANDS='list ls create:java create:static remove rm build enablessl info deploy'

_{{scriptname}}() {
	local cur prev opts

	COMPREPLY=()

	cur="${COMP_WORDS[COMP_CWORD]}"
	prev="${COMP_WORDS[COMP_CWORD-1]}"

	case $prev in
		{{scriptname}})
			COMPREPLY=( $(compgen -W "$SERVER_SUBCOMMANDS" -- $cur) )
			;;
		db)
			COMPREPLY=( $(compgen -W "$DB_SUBCOMMANDS" -- $cur) )
			;;
		site)
			COMPREPLY=( $(compgen -W "$SITE_SUBCOMMANDS" -- $cur) )
			;;
		*)
			COMPREPLY=( $(compgen -X '' -f "${cur}") )
			;;
	esac
}

complete -o bashdefault -o filenames -F _{{scriptname}} {{scriptname}}
