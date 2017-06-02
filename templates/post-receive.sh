#!/bin/bash

SITE_DIR=$HOME/{{site}}

echo '--------------------------------------------------'

tmp_repo=$(mktemp -d)
git clone $(pwd) $tmp_repo
cd $tmp_repo

if [[ -f $SITE_DIR/.config ]]; then
	source $SITE_DIR/.config
	if [[ ! -z "$source" ]] && [[ ! -z "$destination" ]]; then
		cp $SITE_DIR/$source $tmp_repo/$destination
	fi
fi

if [[ -f .build_config ]]; then
	source .build_config

	echo ' > Building...'
	[[ $? -ne 0 ]] && exit 1

	$BUILD_COMMAND
	if [[ $? -ne 0 ]]; then
		echo 'It looks like your build command failed! Aborting...'
		exit 1
	fi
	if [[ ! -f $WAR_FILE ]]; then
		echo "$WAR_FILE not found!"
		exit 1
	fi

	rm -f /opt/tomcat/{{site}}/ROOT.war
	mv $WAR_FILE /opt/tomcat/{{site}}/ROOT.war
	echo '{{site}} deployed!'
elif [[ -f install.sh ]]; then
	bash install.sh
fi

rm -rf $tmp_file

echo '--------------------------------------------------'
echo '> Thanks For Pushing!'
echo '--------------------------------------------------'
