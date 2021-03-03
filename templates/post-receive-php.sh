#!/bin/bash

umask 0002

SITE_DIR=/srv/{{site}}

log() {
	echo "[post-receive]: $@"
}

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
	export SITE_DIR
	log 'Running cods.sh'
	bash cods.sh
fi

log '--------------------------------------------------'
log '> All done!'
log '--------------------------------------------------'
