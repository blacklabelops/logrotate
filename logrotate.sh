#!/bin/bash
#
# Helper functions for configuration and running logrotate.

# Resetting the default configuration file for
# repeated starts.
function resetConfigurationFile() {
  if [ -f "/usr/bin/logrotate.d/logrotate.conf" ]; then
    rm -f /usr/bin/logrotate.d/logrotate.conf
  else
    touch /usr/bin/logrotate.d/logrotate.conf
  fi

  cat >> /usr/bin/logrotate.d/logrotate.conf <<EOF
# deactivate mail
nomail

# move the log files to another directory?
${logrotate_olddir}
EOF
}

# Logrotate status file handling
readonly logrotate_logstatus=${LOGROTATE_STATUSFILE:-"/logrotate-status/logrotate.status"}

logrotate_olddir=""

function resolveOldDir() {
  if [ -n "${LOGROTATE_OLDDIR}" ]; then
    logrotate_olddir="olddir "${LOGROTATE_OLDDIR}
  fi
}

syslogger_command=""

function resolveSysloggerCommand() {
  local syslogger_tag=""

  if [ -n "${SYSLOGGER_TAG}" ]; then
    syslogger_tag=" -t "${SYSLOGGER_TAG}
  fi

  if [ -n "${SYSLOGGER}" ]; then
    syslogger_command="logger "${syslogger_tag}
  fi
}

logrotate_mode="copytruncate"
function resolveLogrotateMode() {
  if [ -n "${LOGROTATE_MODE}" ]; then
    logrotate_mode="${LOGROTATE_MODE}"
  fi
}

logrotate_logfile_compression="nocompress"
logrotate_logfile_compression_delay=""

function resolveLogfileCompression() {
  if [ -n "${LOGROTATE_COMPRESSION}" ]; then
    logrotate_logfile_compression=${LOGROTATE_COMPRESSION}
    if [ ! "${logrotate_logfile_compression}" = "nocompress" ] && [ "${LOGROTATE_DELAYCOMPRESS}" != "false" ]; then
      logrotate_logfile_compression_delay="delaycompress"
    fi
  fi
}

logrotate_interval=${LOGROTATE_INTERVAL:-""}

logrotate_copies=${LOGROTATE_COPIES:-"5"}

logrotate_size=""

function resolveLogrotateSize() {
  if [ -n "${LOGROTATE_SIZE}" ]; then
    logrotate_size="size "${LOGROTATE_SIZE}
  fi
}

logrotate_minsize=""

function resolveMinSize() {
  if [ -n "${LOGROTATE_MINSIZE}" ]; then
    logrotate_minsize="minsize ${LOGROTATE_MINSIZE}"
  fi
}

logrotate_maxage=""

function resolveMaxAge() {
  if [ -n "${LOGROTATE_MAXAGE}" ]; then
    logrotate_maxage="maxage ${LOGROTATE_MAXAGE}"
  fi
}

logrotate_autoupdate=true

function resolveLogrotateAutoupdate() {
  if [ -n "${LOGROTATE_AUTOUPDATE}" ]; then
    logrotate_autoupdate="$(echo ${LOGROTATE_AUTOUPDATE,,})"
  fi
}

logrotate_prerotate=${LOGROTATE_PREROTATE_COMMAND:-""}

logrotate_postrotate=${LOGROTATE_POSTROTATE_COMMAND:-""}

logrotate_lastaction=${LOGROTATE_LASTACTION_COMMAND:-""}

logrotate_dateformat=${LOGROTATE_DATEFORMAT:-""}

resolveSysloggerCommand
resolveOldDir
resolveLogrotateMode
resolveLogfileCompression
resolveLogrotateSize
resolveLogrotateAutoupdate
resolveMinSize
resolveMaxAge
