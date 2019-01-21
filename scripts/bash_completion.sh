# provide completions based on the passed arguments
_cods_complete() {
	local cur="${COMP_WORDS[COMP_CWORD]}"
	COMPREPLY=( $(compgen -W "$*" -- $cur) )
}

# used to indicate no further completions are available
_cods_dont_complete() {
	COMPREPLY=()
}

# do filename completion
_cods_complete_files() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
	COMPREPLY=( $(compgen -X '' -f "${cur}") )
}

_{{scriptname}}() {
	local cur prev subcommand subsubcommand server_subcommands
	local db_subcommands site_subcommands

	server_subcommands='site db devserver login upload restart reboot info'
	server_subcommands+=' adduser addkey autorenew ping credentials pipe'
	server_subcommands+=' bash-completion destroy ports tmux _test'

	db_subcommands='create backup run remove rm list ls login'
	site_subcommands='list ls create remove rm build enablessl info logs'

	COMPREPLY=()

    prev="${COMP_WORDS[COMP_CWORD-1]}"
	subcommand=${COMP_WORDS[1]}

	case $subcommand in
		# no further completions for any of these
		devserver|login|info|ports|ping|swapon|autorenew|reboot|run|credentials|destroy|bash-completion)
			_cods_dont_complete;;
		upload)
			case $prev in
				-f|--file) _cods_complete_files;;
				-d|--destination) _cods_dont_complete;;
				*) _cods_complete -f -d --file --destination ;;
			esac ;;
		restart) _cods_complete -s --service;;
		addkey)
			case $prev in
				-f|--sshkeyfile) _cods_complete_files;;
				*) _cods_complete -f --sshkeyfile ;;
			esac ;;
		adduser)
			case $prev in
				-f|--sshkeyfile) _cods_complete_files;;
				*) _cods_complete -u --username -f --sshkeyfile --github-username;;
			esac ;;
		site)
			if [[ $prev == --domain || $prev == -d ]] ; then
				# it would be really cool if we could complete existing domain
				# names setup on the server...
				# _cods_complete zach.lol static.zach.lol handouts.zach.lol nestor.zach.lol notes.zach.lol
				_cods_dont_complete
				return
			fi
			subsubcommand=${COMP_WORDS[2]}
			case $subsubcommand in
				create) _cods_complete --static --python --node --java --enable-ssl --spring-boot -p --port --domain -d ;;
				build|enablessl|info) _cods_complete -d --domain;;
				list|ls) _cods_dont_complete ;;
				remove|rm) _cods_complete --force -f --domain -d;;
				logs) _cods_complete -d --domain -f --follow;;
				*) _cods_complete $site_subcommands ;;
			esac
			;;
		_test)
			if [[ ${COMP_WORDS[2]} == deploy ]] ; then
				_cods_complete java static node python
			elif [[ $prev == _test ]] ; then
				_cods_complete util site setup deploy
			else
				_cods_dont_complete
			fi
			;;
		db)
			subsubcommand=${COMP_WORDS[2]}
			case $subsubcommand in
				create|remove|rm) _cods_complete --name -n --user -u ;;
				login|list|ls) _cods_dont_complete ;;
				backup)
					case $prev in
						-o|--outfile) _cods_complete_files;;
						*) _cods_complete --name -n -o --outfile ;;
					esac ;;
				*) _cods_complete $db_subcommands
			esac
			;;
		*) _cods_complete $server_subcommands ;;
	esac
}

complete -o bashdefault -o filenames -F _{{scriptname}} {{scriptname}}
