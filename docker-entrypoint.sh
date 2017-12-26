#!/bin/bash
#
# A helper script for ENTRYPOINT.

set -e

[[ ${DEBUG} == true ]] && set -x

source /usr/bin/logrotate.d/logrotate.sh
source /usr/bin/logrotate.d/logrotateConf.sh

resetConfigurationFile

if [ -n "${DELAYED_START}" ]; then
  sleep ${DELAYED_START}
fi

#Create Logrotate Conf
source /usr/bin/logrotate.d/logrotateCreateConf.sh

cat /usr/bin/logrotate.d/logrotate.conf

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

if [ -n "${LOGROTATE_INTERVAL}" ]; then
  case "$LOGROTATE_INTERVAL" in
    hourly)
      logrotate_croninterval='@hourly'
    ;;
    daily)
      logrotate_croninterval='@daily'
    ;;
    weekly)
      logrotate_croninterval='@weekly'
    ;;
    monthly)
      logrotate_croninterval='@monthly'
    ;;
    yearly)
      logrotate_croninterval='@yearly'
    ;;
    *)
      logrotate_croninterval="1 0 0 * * *"
    ;;
  esac
fi

if [ -n "${LOGROTATE_CRONSCHEDULE}" ]; then
  logrotate_croninterval=${LOGROTATE_CRONSCHEDULE}
fi

logrotate_cron_timetable="/usr/sbin/logrotate ${logrotate_parameters} --state=${logrotate_logstatus} /usr/bin/logrotate.d/logrotate.conf ${logrotate_cronlog}"

# ----- Cron Start ------

if [ "$1" = 'cron' ]; then
  if [ ${logrotate_autoupdate} = "true" ]; then
    exec /usr/bin/go-cron "${logrotate_croninterval}" /bin/bash -c "/usr/bin/logrotate.d/update-logrotate.sh; ${logrotate_cron_timetable}"
    exit
  fi

  exec /usr/bin/go-cron "${logrotate_croninterval}" /bin/bash -c "${logrotate_cron_timetable}"
fi

#-----------------------

exec "$@"
