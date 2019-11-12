#!/usr/bin/env bash

if [[ ! -d env ]] ; then
	echo 'env directory not found!'
	exit 1
fi

source env/bin/activate
python3 server.py
