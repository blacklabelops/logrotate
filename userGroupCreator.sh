#!/bin/bash


# DOCUMENTATION
# logrotate won't work with 
# a) files with unknown users
# b) if unknown user, then the directory must have closed permissions
# due to the nature of our containers, most of our users don't map to other containers
# the ones that do map are accidental
# due to writing all logs to a single directory, we need to keep the logging directory open
# this script takes files and checks for UNKNOWN groups or users
# and creates users/groups on-the-fly if needed
# these users have no meaning and creating a new container will lead to new usernames

declare -r LOG_FILE_PATH="${1}"

set -e                      # exit all shells if script fails
set -u                      # exit script if uninitialized variable is used
set -o pipefail             # exit script if anything fails in pipe


function createGroup(){
    # create a new group assigned to the given file's gid
    local -r file_path="${1}"

    local -r gid="$( stat -c '%g' "${file_path}" )"
    local -r group="fakegroup-$(date +%s)"
    sleep 1 # allow date to lapse

    addgroup \
        -g "${gid}" \
        -S "${group}"
}


function createUser(){
    # create a new user assigned to the given file's uid
    local -r file_path="${1}"

    local -r uid="$( stat -c '%u' "${file_path}" )"
    local -r user="fakeuser-$(date +%s)"
    sleep 1 # allow date to lapse

    adduser \
        -S "${user}" \
        -D \
        -H \
        -u "${uid}"
}


function processLogFile(){
    # check the given file for an associated user and group
    # if either an UNKNOWN group or user, a user and/or group is randomly generated
    # with the uid/gid assigned to the file
    local -r file_path="${1}"

    local -r user="$( stat -c '%U' "${file_path}" )"
    local -r group="$( stat -c '%G' "${file_path}" )"

    if [[ "${group}" == 'UNKNOWN' ]]; then
        createGroup "${file_path}" || true
    fi

    if [[ "${user}" == 'UNKNOWN' ]]; then
        createUser "${file_path}"  || true
    fi
}


#########################
# MAIN ##################
#########################

function main(){
    if [[ -f "${LOG_FILE_PATH}" ]]; then
        processLogFile "${LOG_FILE_PATH}"
    else
        exit 1
    fi
}
main



