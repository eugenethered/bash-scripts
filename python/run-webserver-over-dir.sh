#!/bin/bash
#
# run a simple python webserver over the provided current dir

CURRENT_DIR=$PWD

echo "Running python webserver over dir:$CURRENT_DIR"

python3 -m http.server --directory $CURRENT_DIR

