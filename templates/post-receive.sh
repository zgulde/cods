#!/bin/bash

umask 0002

SITE_DIR=/srv/{{site}}
JAR_TARGET_LOCATION=/srv/{{site}}/app.jar

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

# only deploy to the master branch
while read old new ref; do
    branch=$(git rev-parse --symbolic --abbrev-ref $ref)
    if [[ $branch != "master" && $branch != "main" ]]; then
        log "'$branch' is not 'master'. A build is only triggered when pushing the master branch."
		log "'$branch' was successfully pushed, but project was not built."
		log
		log 'Have a great day!'
        exit 0
    fi
done

log "cloning project to '$TMP_REPO'..."

git clone $(pwd) $TMP_REPO
cd $TMP_REPO

if [[ -f $SITE_DIR/cods-config ]]; then
	source $SITE_DIR/cods-config
	if [[ ! -z "$source" ]] && [[ ! -z "$destination" ]]; then
		log "Found configuration file: '${SITE_DIR}/cods-config'!"
		log "Copying $source file to $destination..."
		cp $SITE_DIR/$source $TMP_REPO/$destination
	else
		log "Configuration file found '${SITE_DIR}/cods-config', but \$source and \$destination are not set."
		log 'Nothing copied. Continuing...'
	fi
else
	log "No configuration file ($SITE_DIR/cods-config) found. Continuing..."
fi

if [[ -f .cods ]]; then
	log 'Found ".cods" file! Building based on this file...'
	source .cods

	if [[ -z $BUILD_COMMAND ]]; then
		log '$BUILD_COMMAND not set! (Check the .cods file)'
		log 'Aborting...'
		exit 1
	fi
	if [[ -z $JAR_FILE ]]; then
		log '$JAR_FILE not set! (Check the .cods file)'
		log 'Aborting...'
		exit 1
	fi

	log '--------------------------------------------------'
	log '> Building...'
	log '--------------------------------------------------'
	log
	log "> $BUILD_COMMAND"

	eval "$BUILD_COMMAND"

	# checks for successful building
	if [[ $? -ne 0 ]]; then
		log 'It looks like your build command failed (exited with a non-zero code)!'
		log 'Aborting...'
		exit 1
	fi
	if [[ ! -f $JAR_FILE ]]; then
		log "Build was successful, but jar file: '$JAR_FILE' was not found!"
		log 'Aborting...'
		exit 1
	fi

	log "Build success! Deploying $JAR_FILE to $JAR_TARGET_LOCATION..."
	rm -f $JAR_TARGET_LOCATION
	mv $JAR_FILE $JAR_TARGET_LOCATION

elif [[ -f cods.sh ]]; then
	log 'Found "cods.sh"! Running...'
	log "Exporting SITE_DIR=$SITE_DIR, JAR_TARGET_LOCATION=$JAR_TARGET_LOCATION, TMP_REPO=$TMP_REPO"
	export SITE_DIR
	export JAR_TARGET_LOCATION
	export TMP_REPO
	bash cods.sh
else
	log 'No ".cods" file or "cods.sh" file found.'
fi

log 'Restarting {{site}}...'
sudo systemctl restart {{site}}

log '{{site}} deployed!'

log '--------------------------------------------------'
log '> All done!'
log '--------------------------------------------------'
