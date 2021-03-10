#!/bin/bash
#
# run a simple node webserver and serve files from the supplied dir

WEB_SOURCE_DIR=$1

node webserver.js $WEB_SOURCE_DIR


