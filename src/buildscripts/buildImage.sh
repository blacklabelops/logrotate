#!/bin/bash -x

set -o errexit    # abort script at first error

function buildImage() {
  local tagname=$1
  local version=$2
  local branch=$BUILD_BRANCH
  docker build --no-cache -t blacklabelops/logrotate:$tagname .
}

buildImage $1 $2
