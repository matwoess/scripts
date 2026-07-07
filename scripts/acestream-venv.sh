#!/usr/bin/env bash

# Install acestream-launcher in new virtual environment
python -m venv venv
venv/bin/pip install acestream-launcher setuptools

# Make sure everything is installed
venv/bin/pip list 
#Package            Version
#------------------ -------
#acestream          0.2.0
#acestream-launcher 2.1.0
#pip                25.3
#setuptools         80.9.0

# Try invoking the tool
venv/bin/acestream-launcher --help

echo "[[ DONE ]]"
