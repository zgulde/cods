#!/bin/bash

SITE_DIR=/srv/{{site}}
WAR_TARGET_LOCATION=/opt/tomcat/{{site}}/ROOT.war

TMP_REPO=$(mktemp -d)

log() {
	echo "[post-receive]: $@"
}

cleanup() {
	log "cleaning up temp files ($TMP_REPO)..."
	rm -rf $TMP_REPO
}

trap cleanup EXIT

log '---- post-receive script started! ----'
log "cloning project to '$TMP_REPO'..."

git clone $(pwd) $TMP_REPO
cd $TMP_REPO

if [[ -f $SITE_DIR/.config ]]; then
	source $SITE_DIR/.config
	if [[ ! -z "$source" ]] && [[ ! -z "$destination" ]]; then
		log "Found configuration file: '${SITE_DIR}/.config'!"
		log "Copying $source file to $destination..."
		cp $SITE_DIR/$source $TMP_REPO/$destination
	else
		log 'Configuration file found, but $source and $destination are not set.'
		log 'Nothing copied. Continuing...'
	fi
else
	log "No configuration file ($SITE_DIR/.config) found. Continuing..."
fi

if [[ -f .build_config ]]; then
	source .build_config

	if [[ -z $BUILD_COMMAND ]]; then
		log '$BUILD_COMMAND not set! (Check the .build_config file)'
		log 'Aborting...'
		exit 1
	fi
	if [[ -z $WAR_FILE ]]; then
		log '$WAR_FILE not set! (Check the .build_config file)'
		log 'Aborting...'
		exit 1
	fi

	log '--------------------------------------------------'
	log '> Building...'
	log '--------------------------------------------------'
	log
	log "> $BUILD_COMMAND"

	$BUILD_COMMAND

	# checks for successful building
	if [[ $? -ne 0 ]]; then
		log 'It looks like your build command failed (exited with a non-zero code)!'
		log 'Aborting...'
		exit 1
	fi
	if [[ ! -f $WAR_FILE ]]; then
		log "Build was successful, but war file: '$WAR_FILE' was not found!"
		log 'Aborting...'
		exit 1
	fi

	log "Build success! Deploying $WAR_FILE to $WAR_TARGET_LOCATION..."
	rm -f $WAR_TARGET_LOCATION
	mv $WAR_FILE $WAR_TARGET_LOCATION

	log '{{site}} deployed!'

elif [[ -f install.sh ]]; then
	log 'Found "install.sh"! Running...'
	export SITE_DIR
	export WAR_TARGET_LOCATION
	export TMP_REPO
	bash install.sh
else
	log 'No ".build_config" file or "install.sh" file found.'
fi

log '--------------------------------------------------'
log '> All done!'
log '--------------------------------------------------'
