#!/bin/bash

echo '--------------------------------------------------'
tmp_file=$(mktemp -d)
git clone $(pwd) $tmp_file
cd $tmp_file

if [[ -f .build_config ]]; then
	source .build_config

	# sudo here to prompt for admin access and bail out if we don't
	# have it
	sudo echo ' > Building...'
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

	# rm -rf /opt/tomcat/{{site}}/*
	# mv $WAR_FILE /opt/tomcat/{{site}}/ROOT.war
	# echo '{{site}} deployed!'
elif [[ -f install.sh ]]; then
	bash install.sh
fi

rm -rf $tmp_file

echo '--------------------------------------------------'
echo '> Thanks For Pushing!'
echo '--------------------------------------------------'
