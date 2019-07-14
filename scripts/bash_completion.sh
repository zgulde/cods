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
	local db_subcommands site_subcommands user_subcommands

	server_subcommands='site db login upload restart reboot info tmux'
	server_subcommands+=' user addkey autorenew ping credentials pipe ports'
	server_subcommands+=' bash-completion destroy _test switch-java-version'

	db_subcommands='create backup run remove rm list ls login'
	site_subcommands='list ls create remove rm build enablehttps info logs'
	user_subcommands='add remove rm'

	COMPREPLY=()

    prev="${COMP_WORDS[COMP_CWORD-1]}"
	subcommand=${COMP_WORDS[1]}

	case $subcommand in
		# no further completions for any of these
		login|info|ports|ping|swapon|autorenew|reboot|run|destroy|bash-completion)
			_cods_dont_complete;;
		credentials) _cods_complete path edit add ;;
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
				create) _cods_complete --static --python --node --java --enable-https --spring-boot -p --port --domain -d --php ;;
				build|enablehttps|info) _cods_complete -d --domain;;
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
		user)
			subsubcommand=${COMP_WORDS[2]}
			case $subsubcommand in
				add) _cods_complete -f --sshkeyfile -u --username --github-username;;
				rm|remove) _cods_complete -u --username ;;
				*) _cods_complete $user_subcommands
			esac
			;;
		*) _cods_complete $server_subcommands ;;
	esac
}

complete -o bashdefault -o filenames -F _{{scriptname}} {{scriptname}}
