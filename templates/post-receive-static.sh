#!/bin/bash

SITE_DIR=/srv/{{site}}
TARGET_LOCATION=/srv/{{site}}/public
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

if [[ -f $SITE_DIR/config ]]; then
	source $SITE_DIR/config
	if [[ ! -z "$source" ]] && [[ ! -z "$destination" ]]; then
		log "Found configuration file: '${SITE_DIR}/config'!"
		log "Copying $source file to $destination..."
		cp $SITE_DIR/$source $TMP_REPO/$destination
	else
		log "Configuration file found '${SITE_DIR}/config', but $source and $destination are not set."
		log 'Nothing copied. Continuing...'
	fi
else
	log "No configuration file ($SITE_DIR/config) found. Continuing..."
fi

if [[ -f install.sh ]]; then
	log 'Found "install.sh"! Running...'
	export SITE_DIR
	export TARGET_LOCATION
	export TMP_REPO
	bash install.sh
else
	log 'No "install.sh" file found.'
	log "Replacing all files in $TARGET_LOCATION with this project"
	mv -v $TMP_REPO/* $TARGET_LOCATION
fi

log '--------------------------------------------------'
log '> All done!'
log '--------------------------------------------------'
