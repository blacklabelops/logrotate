#!/bin/bash -x

#------------------
# CONTAINER VARIABLES
#------------------
export IMAGE_VERSION=1.3
export BUILD_BRANCH=$(git branch | grep -e "^*" | cut -d' ' -f 2)
