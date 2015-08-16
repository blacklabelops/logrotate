#!/bin/bash -x
#
# A helper script for ENTRYPOINT.

set -e

# Resetting the default configuration file for
# repeated starts.
if [ -f "/opt/logrotate/logrotate.conf" ]; then
  rm -f /opt/logrotate/logrotate.conf
fi

log_command=""

if [ -n "${LOG_FILE}" ]; then
 log_command=" 2>&1 | tee -a "${LOG_FILE}
 touch ${LOG_FILE}
fi

if [ -n "${DELAYED_START}" ]; then
  sleep ${DELAYED_START}
fi

logrotate_olddir=""

if [ -n "${LOGROTATE_OLDDIR}" ]; then
  logrotate_olddir="olddir "${LOGROTATE_OLDDIR}
fi

logrotate_logfile_compression="nocompress"

if [ -n "${LOGROTATE_COMPRESSION}" ]; then
  logrotate_logfile_compression=${LOGROTATE_COMPRESSION}
fi

logrotate_interval="daily"

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

touch /opt/logrotate/logrotate.conf

cat >> /opt/logrotate/logrotate.conf <<EOF
# rotate log files
${logrotate_interval}

# keep backlogs x times
rotate ${logrotate_copies}

# use date as a suffix of the rotated file
dateext

# maximum file size rotation?
${logrotate_size}

# log files compression?
${logrotate_logfile_compression}

# move the log files to another directory?
${logrotate_olddir}

EOF

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
      echo "Processing $f file..."
      file_owner_user=$(stat -c %U ${f})
      file_owner_group=$(stat -c %G ${f})
      cat >> /opt/logrotate/logrotate.conf <<_EOF_
${f} {
  su ${file_owner_user} ${file_owner_group}
  missingok
}
_EOF_
    fi
  done
done

cat /opt/logrotate/logrotate.conf

logrotate_cronlogfile=""

if [ -n "${LOGROTATE_LOGFILE}" ]; then
  logrotate_cronlogfile=" 2>&1 | tee -a "${logrotate_cronlogfile}${LOGROTATE_LOGFILE}
fi

logrotate_croninterval=""

if [ -n "${LOGROTATE_CRONSCHEDULE}" ]; then
  logrotate_croninterval=${LOGROTATE_CRONSCHEDULE}
else
  logrotate_croninterval="@"${logrotate_interval}
fi

crontab <<EOF
${logrotate_croninterval} /usr/sbin/logrotate -v /opt/logrotate/logrotate.conf ${logrotate_cronlogfile}
EOF

crontab -l

log_command=""

if [ -n "${LOG_FILE}" ]; then
  log_command=" 2>&1 | tee -a "${LOG_FILE}
fi

if [ "$1" = 'cron' ]; then
  croncommand="crond -n -x sch"${log_command}
  bash -c "${croncommand}"
fi

exec "$@"
