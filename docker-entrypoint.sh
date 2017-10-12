#!/bin/bash -x
#
# A helper script for ENTRYPOINT.

set -e

syslogger_tag=""

if [ -n "${SYSLOGGER_TAG}" ]; then
  syslogger_tag=" -t "${SYSLOGGER_TAG}
fi

syslogger_command=""

if [ -n "${SYSLOGGER}" ]; then
  syslogger_command="logger "${syslogger_tag}
fi

function output()
{
  if [ -n "${SYSLOGGER}" ]; then
    logger ${syslogger_tag} "$@"
  fi
  echo "$@"
}

# Logrotate status file handling

logrotate_logstatus="/logrotate-status/logrotate.status"

if [ -n "${LOGROTATE_STATUSFILE}" ]; then
  logrotate_logstatus=${LOGROTATE_STATUSFILE}
fi

if [ -n "${DELAYED_START}" ]; then
  sleep ${DELAYED_START}
fi

# ----- Crontab Generation ------

logrotate_parameters=""

if [ -n "${LOGROTATE_PARAMETERS}" ]; then
  logrotate_parameters="-"${LOGROTATE_PARAMETERS}
fi

logrotate_cronlog=""

if [ -n "${LOGROTATE_LOGFILE}" ] && [ -z "${SYSLOGGER}"]; then
  logrotate_cronlog=" 2>&1 | tee -a "${LOGROTATE_LOGFILE}
else
  if [ -n "${SYSLOGGER}" ]; then
    logrotate_cronlog=" 2>&1 | "${syslogger_command}
  fi
fi

logrotate_croninterval="1 0 0 * * *"

if [ -n "${LOGROTATE_CRONSCHEDULE}" ]; then
  logrotate_croninterval=${LOGROTATE_CRONSCHEDULE}
fi

logrotate_cron_timetable="/usr/sbin/logrotate ${logrotate_parameters} --state=${logrotate_logstatus} /usr/bin/logrotate.d/logrotate.conf ${logrotate_cronlog}"

# ----- Cron Start ------

if [ "$1" = 'cron' ]; then
  /usr/bin/go-cron "${logrotate_croninterval}" /bin/bash -c "${logrotate_cron_timetable}"
fi

#-----------------------

exec "$@"
