#!/usr/bin/env bash

set -u

# Script used for deployment with cods (https://github.com/zgulde/cods)

cd $SITE_DIR

echo "[cods.sh] (re-)creating the venv"
echo '[cods.sh] - rm -rf env'
rm -rf env
echo '[cods.sh] python3 -m venv env'
python3 -m venv env
echo '[cods.sh] source env/bin/activate'
source env/bin/activate
echo '[cods.sh] python3 -m pip install -r requirements.txt'
python3 -m pip install -r requirements.txt
