#!/bin/bash
#
# A helper script for updating the /usr/bin/logrotate.d/logrotate.conf.

set -e

[[ ${DEBUG} == true ]] && set -x

source /usr/bin/logrotate.d/logrotate.sh
source /usr/bin/logrotate.d/logrotateConf.sh

resetConfigurationFile

#Create Logrotate Conf
source /usr/bin/logrotate.d/logrotateCreateConf.sh
