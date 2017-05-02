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

# Resetting the default configuration file for
# repeated starts.
if [ -f "/usr/bin/logrotate.d/logrotate.conf" ]; then
  rm -f /usr/bin/logrotate.d/logrotate.conf
fi

if [ -n "${DELAYED_START}" ]; then
  sleep ${DELAYED_START}
fi

# ----- Logrotate Config File Generation ------

logrotate_olddir=""

if [ -n "${LOGROTATE_OLDDIR}" ]; then
  logrotate_olddir="olddir "${LOGROTATE_OLDDIR}
fi

logrotate_logfile_compression="nocompress"
logrotate_logfile_compression_delay=""

if [ -n "${LOGROTATE_COMPRESSION}" ]; then
  logrotate_logfile_compression=${LOGROTATE_COMPRESSION}
  if [ ! "${logrotate_logfile_compression}" = "nocompress" ]; then
    logrotate_logfile_compression_delay="delaycompress"
  fi
fi

logrotate_interval=""

if [ -n "${LOGROTATE_INTERVAL}" ]; then
  logrotate_interval=${LOGROTATE_INTERVAL}
fi

logrotate_copies="5"

if [ -n "${LOGROTATE_COPIES}" ]; then
  logrotate_copies=${LOGROTATE_COPIES}
fi

logrotate_size=""

if [ -n "${LOGROTATE_SIZE}" ]; then
  logrotate_size="size "${LOGROTATE_SIZE}
fi

logrotate_autoupdate=true

if [ -n "${LOGROTATE_AUTOUPDATE}" ]; then
  logrotate_autoupdate="$(echo ${LOGROTATE_AUTOUPDATE,,})"
fi

touch /usr/bin/logrotate.d/logrotate.conf

cat >> /usr/bin/logrotate.d/logrotate.conf <<EOF
# deactivate mail
mail nomail

# move the log files to another directory?
${logrotate_olddir}

EOF

# ----- Logfile Crawling ------

log_dirs=""

if [ -n "${LOGS_DIRECTORIES}" ]; then
  log_dirs=${LOGS_DIRECTORIES}
else
  log_dirs=${log_dir}
fi

logs_ending="log"
LOGS_FILE_ENDINGS_INSTRUCTION=""

if [ -n "${LOG_FILE_ENDINGS}" ]; then
  logs_ending=${LOG_FILE_ENDINGS}
fi

SAVEIFS=$IFS
IFS=' '
COUNTER=0
for ending in $logs_ending
do
  if [ "$COUNTER" -eq "0" ]; then
    LOGS_FILE_ENDINGS_INSTRUCTION="$LOGS_FILE_ENDINGS_INSTRUCTION -iname "*.${ending}""
  else
    LOGS_FILE_ENDINGS_INSTRUCTION="$LOGS_FILE_ENDINGS_INSTRUCTION -o -iname "*.${ending}""
  fi
  let COUNTER=COUNTER+1
done
IFS=$SAVEIFS

for d in ${log_dirs}
do
  for f in $(find ${d} -type f $LOGS_FILE_ENDINGS_INSTRUCTION);
  do
    if [ -f "${f}" ]; then
      output "Processing $f file..."
      file_owner_user=$(stat -c %U ${f})
      file_owner_group=$(stat -c %G ${f})
      if [ "$file_owner_user" != "UNKNOWN" ] && [ "$file_owner_group" != "UNKNOWN" ]; then
        cat >> /usr/bin/logrotate.d/logrotate.conf <<_EOF_
${f} {
  su ${file_owner_user} ${file_owner_group}
  copytruncate
  rotate ${logrotate_copies}
  missingok
_EOF_
        if [ -n "${logrotate_logfile_compression}" ]; then
          cat >> /usr/bin/logrotate.d/logrotate.conf <<_EOF_
  ${logrotate_logfile_compression}
_EOF_
        fi
        if [ -n "${logrotate_logfile_compression_delay}" ]; then
          cat >> /usr/bin/logrotate.d/logrotate.conf <<_EOF_
  ${logrotate_logfile_compression_delay}
_EOF_
        fi
        if [ -n "${logrotate_interval}" ]; then
          cat >> /usr/bin/logrotate.d/logrotate.conf <<_EOF_
  ${logrotate_interval}
_EOF_
        fi
        if [ -n "${logrotate_size}" ]; then
          cat >> /usr/bin/logrotate.d/logrotate.conf <<_EOF_
  ${logrotate_size}
_EOF_
        fi
        if [ -n "${LOGROTATE_DATEFORMAT}" ]; then
          cat >> /usr/bin/logrotate.d/logrotate.conf <<_EOF_
  dateext
  dateformat ${LOGROTATE_DATEFORMAT}
_EOF_
        fi
        cat >> /usr/bin/logrotate.d/logrotate.conf <<_EOF_
}
_EOF_
      else
        output "File has unknown user or group: ${f}, user: ${file_owner_user}, group: ${file_owner_group}"
      fi
    fi
  done
done

cat /usr/bin/logrotate.d/logrotate.conf

# ----- Take all Log in Subfolders ------

all_log_dirs=""

if [ -n "${ALL_LOGS_DIRECTORIES}" ]; then
  all_log_dirs=${ALL_LOGS_DIRECTORIES}
fi

for d in ${all_log_dirs}
do
  for f in $(find ${d} -type f);
  do
    if [ -f "${f}" ]; then
      output "Processing $f file..."
      file_owner_user=$(stat -c %U ${f})
      file_owner_group=$(stat -c %G ${f})
      if [ "$file_owner_user" != "UNKNOWN" ] && [ "$file_owner_group" != "UNKNOWN" ]; then
        cat >> /usr/bin/logrotate.d/logrotate.conf <<_EOF_
${f} {
  su ${file_owner_user} ${file_owner_group}
  copytruncate
  rotate ${logrotate_copies}
  missingok
_EOF_
        if [ -n "${logrotate_logfile_compression}" ]; then
          cat >> /usr/bin/logrotate.d/logrotate.conf <<_EOF_
  ${logrotate_logfile_compression}
_EOF_
        fi
        if [ -n "${logrotate_logfile_compression_delay}" ]; then
          cat >> /usr/bin/logrotate.d/logrotate.conf <<_EOF_
  ${logrotate_logfile_compression_delay}
_EOF_
        fi
        if [ -n "${logrotate_interval}" ]; then
          cat >> /usr/bin/logrotate.d/logrotate.conf <<_EOF_
  ${logrotate_interval}
_EOF_
        fi
        if [ -n "${logrotate_size}" ]; then
          cat >> /usr/bin/logrotate.d/logrotate.conf <<_EOF_
  ${logrotate_size}
_EOF_
        fi
        if [ -n "${LOGROTATE_DATEFORMAT}" ]; then
          cat >> /usr/bin/logrotate.d/logrotate.conf <<_EOF_
  dateext
  dateformat ${LOGROTATE_DATEFORMAT}
_EOF_
        fi
        cat >> /usr/bin/logrotate.d/logrotate.conf <<_EOF_
}
_EOF_
      else
        output "File has unknown user or group: ${f}, user: ${file_owner_user}, group: ${file_owner_group}"
      fi
    fi
  done
done

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

if [ -n "${LOGROTATE_CRONSCHEDULE}" ]; then
  logrotate_croninterval=${LOGROTATE_CRONSCHEDULE}
fi

logrotate_cron_timetable="/usr/sbin/logrotate ${logrotate_parameters} --state=${logrotate_logstatus} /usr/bin/logrotate.d/logrotate.conf ${logrotate_cronlog}"

# ----- Cron Start ------

if [ "$1" = 'cron' ]; then
  if [ ${logrotate_autoupdate} = "true" ]; then
    /usr/bin/go-cron "${logrotate_croninterval}" /bin/bash -c "/usr/bin/logrotate.d/update-logrotate.sh; ${logrotate_cron_timetable}"
    exit
  fi

  /usr/bin/go-cron "${logrotate_croninterval}" /bin/bash -c "${logrotate_cron_timetable}"
fi

#-----------------------

exec "$@"
