#!/bin/bash
#
# Helper functions for manipulating logrotate configurationsfile

function createLogrotateConfigurationEntry() {
  local file="$1"
  local file_user="$2"
  local file_owner="$3"
  local conf_copies="$4"
  local conf_logfile_compression="$5"
  local conf_logfile_compression_delay="$6"
  local conf_logrotate_mode="$7"
  local conf_logrotate_interval="$8"
  local conf_logrotate_size="$9"
  local conf_dateformat="${10}"
  local conf_minsize="${11}"
  local conf_maxage="${12}"
  local conf_prerotate="${13}"
  local conf_postrotate="${14}"
  local conf_lastaction="${15}"
  local new_log=
  new_log=${file}" {"
  if [ "$file_user" != "UNKNOWN" ] && [ "$file_owner" != "UNKNOWN" ]; then
    new_log=${new_log}"\n  su ${file_user} ${file_owner}"
  fi
  new_log=${new_log}"\n  rotate ${conf_copies}"
  new_log=${new_log}"\n  missingok"
  if [ -n "${conf_logfile_compression}" ]; then
    new_log=${new_log}"\n  ${conf_logfile_compression}"
  fi
  if [ -n "${conf_logfile_compression_delay}" ]; then
    new_log=${new_log}"\n  ${conf_logfile_compression_delay}"
  fi
  if [ -n "${conf_logrotate_mode}" ]; then
    new_log=${new_log}"\n  ${conf_logrotate_mode}"
  fi
  if [ -n "${conf_logrotate_interval}" ]; then
    new_log=${new_log}"\n  ${conf_logrotate_interval}"
  fi
  if [ -n "${conf_logrotate_size}" ]; then
    new_log=${new_log}"\n  ${conf_logrotate_size}"
  fi
  if [ -n "${conf_minsize}" ]; then
    new_log=${new_log}"\n  ${conf_minsize}"
  fi
  if [ -n "${conf_maxage}" ]; then
    new_log=${new_log}"\n  ${conf_maxage}"
  fi
  if [ -n "${conf_dateformat}" ]; then
    new_log=${new_log}"\n  dateext\n  dateformat ${conf_dateformat}"
  fi
  if [ -n "${conf_prerotate}" ]; then
    new_log=${new_log}"\n  prerotate"
    new_log=${new_log}"\n\t${conf_prerotate}"
    new_log=${new_log}"\n  endscript"
  fi
  if [ -n "${conf_postrotate}" ]; then
    new_log=${new_log}"\n  postrotate"
    new_log=${new_log}"\n\t${conf_postrotate}"
    new_log=${new_log}"\n  endscript"
  fi
  if [ -n "${conf_lastaction}" ]; then
    new_log=${new_log}"\n  lastaction"
    new_log=${new_log}"\n\t${conf_lastaction}"
    new_log=${new_log}"\n  endscript"
  fi
  new_log=${new_log}"\n}"
  echo -e $new_log
}

function insertConfigurationEntry()
{
  local config=$1
  local config_file=$2

  cat >> $config_file <<_EOF_
${config}
_EOF_
}
