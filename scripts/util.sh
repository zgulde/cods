#################################
# A handful of helper functions #
#################################

heading(){
    echo '---------------------------------------------------------------------'
    echo "> $@"
    echo '---------------------------------------------------------------------'
}

confirm() {
	local message=${1:-'Continue?'}
	read -p "${message} [y/N] " input
	[[ $(tr '[:upper:]' '[:lower:]' <<< $input) == y* ]]
}

die() {
    echo "$@"
    exit 1
}

mkpassword() {
	local length=${1:-20}
	echo "$(LC_ALL=C tr -cd 'a-zA-Z0-9' < /dev/urandom | head -c $length)"
}
