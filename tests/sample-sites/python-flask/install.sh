#!/usr/bin/env bash

# Script used for deployment with cods (https://github.com/zgulde/cods)

cd $SITE_DIR

echo "[install.sh] (re-)creating the venv"
echo '[install.sh] - rm -rf env'
rm -rf env
echo '[install.sh] python3 -m venv env'
python3 -m venv env
echo '[install.sh] source env/bin/activate'
source env/bin/activate
echo '[install.sh] python3 -m pip install -r requirements.txt'
python3 -m pip install -r requirements.txt
