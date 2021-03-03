#!/bin/bash

umask 0002

SITE_DIR=/srv/{{site}}

TMP_REPO=$(mktemp -d)

log() {
	echo "[post-receive]: $@"
}

cleanup() {
	log "cleaning up temp files ($TMP_REPO)..."
	rm -rf $TMP_REPO
}

trap cleanup EXIT

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

log 'Checking out the most recent version of the code'
git --work-tree=${SITE_DIR} --git-dir=${SITE_DIR}/repo.git checkout -f master

cd $SITE_DIR

if [[ -f cods.sh ]] ; then
	log "Found cods.sh, running with SITE_DIR=$SITE_DIR"
	export SITE_DIR
	bash cods.sh
fi

log 'Restarting {{site}} service...'
sudo systemctl restart {{site}}

log '--------------------------------------------------'
log '> All done!'
log '--------------------------------------------------'

