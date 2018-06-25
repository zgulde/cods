#################################
# A handful of helper functions #
#################################

repeat() {
	local string=$1
	local n=$2
	local fmt="%-${n}s"
	local s="$(printf $fmt $string)"
	echo -n "${s// /$string}"
}

heading(){
    echo '---------------------------------------------------------------------'
    echo "> $@"
    echo '---------------------------------------------------------------------'
}

die() {
    echo "$@"
    exit 1
}

confirm() {
	local message=${1:-'Continue?'}
	read -p "${message} [y/N] " input
	[[ $(tr '[:upper:]' '[:lower:]' <<< $input) == y* ]]
}

mkpassword() {
	local length=${1:-20}
	echo "$(LC_ALL=C tr -cd 'a-zA-Z0-9' < /dev/urandom | head -c $length)"
}

valid_username() {
	local username=$1
	[[ $username != root && $username =~ ^[a-z][a-zA-Z0-9_]{0,29}$ ]]
}
