#!/bin/bash

umask 0002

SITE_DIR=/srv/{{site}}
PUBLIC_DIR=/srv/{{site}}/public
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

# if we have a build script, run it, else, just do a checkout
if git ls-tree HEAD | cut -f 2 | grep ^.cods$ >/dev/null || git ls-tree HEAD | cut -f 2 | grep ^cods.sh$  ; then

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

	if [[ -f cods.sh ]] ; then
		log 'Found "cods.sh"! Running...'
		log "Exporting SITE_DIR=$SITE_DIR, PUBLIC_DIR=$PUBLIC_DIR, TMP_REPO=$TMP_REPO"
		export SITE_DIR
		export PUBLIC_DIR
		export TMP_REPO
		bash cods.sh
	elif [[ -f .cods ]] ; then
		source .cods

		if [[ -z $BUILD_COMMAND ]]; then
			log '$BUILD_COMMAND not set! (Check the .cods file)'
			log 'Aborting...'
			exit 1
		fi
		if [[ -z $OUTPUT_DIR ]]; then
			log '$OUTPUT_DIR not set! (Check the .cods file)'
			log 'Aborting...'
			exit 1
		fi

		log "Running > $BUILD_COMMAND"
		eval "$BUILD_COMMAND"

		if [[ $? -ne 0 ]] ; then
			log "ERROR: '$BUILD_COMMAND' failed."
			log 'It looks like your build command failed (exited with a non-zero code)!'
			log 'Aborting...'
			exit 1
		fi
		if [[ ! -d $OUTPUT_DIR ]] ; then
			log "ERROR: $OUTPUT_DIR not found."
			log 'Aborting...'
			exit 1
		fi
		log "Moving $OUTPUT_DIR to $SITE_DIR/public..."
		# set the correct permissions and group ownership
		chgrp --recursive {{username}} $OUTPUT_DIR
		chmod g+rwxs $OUTPUT_DIR
		rm -rf ${SITE_DIR}/public
		mv $OUTPUT_DIR ${SITE_DIR}/public
	fi

else
	log "Checking out code to ${SITE_DIR}/public"
	git --work-tree=${SITE_DIR}/public --git-dir=${SITE_DIR}/repo.git checkout -f master
fi

log '--------------------------------------------------'
log '> All done!'
log '--------------------------------------------------'
