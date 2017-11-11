#!/bin/bash

BASE_DIR="$( cd "$( dirname "$0" )" && pwd )"

# modify the right file depending on if we're on MacOS or Linux
if [[ $(uname -s) == "Darwin" ]]; then
	RC_FILE="$HOME/.bash_profile"
else
	RC_FILE="$HOME/.bashrc"
fi

# source the completion when starting a new terminal session
echo '' >> $RC_FILE
echo '# These lines added by tomcat server setup tool script' >> $RC_FILE
echo "# located at $BASE_DIR/$0" >> $RC_FILE
echo '# Load tab completion for the ./server command' >> $RC_FILE
echo "source $BASE_DIR/bash_completion.sh" >> $RC_FILE

echo "Bash tab completion installed in ${RC_FILE}!"
echo 'Either open a new terminal session, or run'
echo
echo "    source $BASE_DIR/bash_completion.sh"
echo


