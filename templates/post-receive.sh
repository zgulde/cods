#!/bin/bash

SITE_DIR=$HOME/{{site}}

echo '--------------------------------------------------'

tmp_repo=$(mktemp -d)
git clone $(pwd) $tmp_repo
cd $tmp_repo

if [[ -f $SITE_DIR/.config ]]; then
	source $SITE_DIR/.config
	if [[ ! -z "$source" ]] && [[ ! -z "$destination" ]]; then
		echo "Found configuration file ${SITE_DIR}/.config!"
        echo "Copying $source file to $destination..."
		cp $SITE_DIR/$source $tmp_repo/$destination
	fi
fi

if [[ -f .build_config ]]; then
	source .build_config

    if [[ -z $BUILD_COMMAND ]]; then
        echo '$BUILD_COMMAND not set! (Check the .build_config file)'
        echo 'Aborting...'
        exit 1
    fi
    if [[ -z $WAR_FILE ]]; then
        echo '$WAR_FILE not set! (Check the .build_config file)'
        echo 'Aborting...'
        exit 1
    fi

	echo ' > Building...'

	$BUILD_COMMAND

	# checks for successful building
	if [[ $? -ne 0 ]]; then
        echo 'It looks like your build command failed (exited with a non-zero code)!'
        echo 'Aborting...'
		exit 1
	fi
	if [[ ! -f $WAR_FILE ]]; then
		echo "Build was successful, but war file: "$WAR_FILE" was not found!"
        echo 'Aborting...'
		exit 1
	fi

	rm -f /opt/tomcat/{{site}}/ROOT.war
	mv $WAR_FILE /opt/tomcat/{{site}}/ROOT.war

	echo '{{site}} deployed!'

elif [[ -f install.sh ]]; then
	bash install.sh
else
	echo 'No ".build_config" file or "install.sh" file found.'
fi

rm -rf $tmp_file

echo '--------------------------------------------------'
echo '> Thanks For Pushing!'
echo '--------------------------------------------------'
