#!/bin/bash
#
# A helper script for updating the /usr/bin/logrotate.d/logrotate.conf.

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

function insertInOrder()
{
  config=$1
  order=$2
  file=$3
  begin=$4
  directory=$5
  _i=$6

  order_arr=($order)

  files=$(grep -n -E "^\s*${directory}.*\{\s*$" $file)

  len=$(echo "${files}" | wc -l)
  if [ ! "$files" ]; then
    len=0
  fi
  unset files_table
  files_table=(${files//:/ })
  unset line

  for i in `seq 0 $(( len - 1 ))`; do
    index=$(( $i * 3 + 1 ))
    if [[ "${order_arr[@]:${_i}}" =~ "${files_table[$index]}" ]]; then
      line=${files_table[$(( $i * 3 ))]}
      break
    fi
  done

  if [[ $len -gt 0 ]]; then
    if [ ! "$line" ]; then
      # insert at available entry after last log path in "${files_table}"
      last_file=${files_table[$(((len - 1)*3 + 1))]}
      last_file=${last_file//\//\\/}
      line_info=$(awk "
        BEGIN {}
          /^ *${last_file} *\{ *$/ {banner = 1; printf NR \" \"; print; next}
          /^ *} *$/ {if (banner) {printf NR \" \"; print}; banner = 0}
          {if (banner) {printf NR \" \"; print }}
        END {}
      " $file)
      line=$(($(echo "${line_info}" | tail -n 1 | cut -f1 -d' ') + 1))
    fi
  else
    line=$begin
  fi

  if [[ $line -lt `cat $file | wc -l` ]]; then
    new_config=$(awk -v n=$line -v config="$config" 'NR == n {print config} {print}' $file)
    echo "$new_config" | tee $file > /dev/null
  else
    echo -e "$config" | tee -a $file > /dev/null
  fi
}

function remove() {
  f=$1
  file=$2
  _f=${f//\//\\/}

  new_config=$(awk "
    BEGIN {}
    /^ *${_f} *\{ *$/ {found=1; next}
    /^ *\/.*\{$/ {found=0}
    { if (! found) {print} }
    END {}
  " $file)
  echo "$new_config" | tee $file > /dev/null
}

# Logrotate status file handling

logrotate_logstatus="/logrotate-status/logrotate.status"

if [ -n "${LOGROTATE_STATUSFILE}" ]; then
  logrotate_logstatus=${LOGROTATE_STATUSFILE}
fi

# ----- Logrotate Config File Generation ------

logrotate_olddir=""

if [ -n "${LOGROTATE_OLDDIR}" ]; then
  logrotate_olddir="olddir "${LOGROTATE_OLDDIR}
fi

# if configuration file doesn't exist, create one
if [ ! -f /usr/bin/logrotate.d/logrotate.conf ]; then
  touch /usr/bin/logrotate.d/logrotate.conf

  cat >> /usr/bin/logrotate.d/logrotate.conf <<EOF
# deactivate mail
mail nomail

# move the log files to another directory?
${logrotate_olddir}

EOF
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

last_line_no=$(cat /usr/bin/logrotate.d/logrotate.conf | wc -l)
for d in ${log_dirs}
do
  unset _d
  _d=${_d//\//\\/}
  _i=-1
  log_files=$(find ${d} -type f $LOGS_FILE_ENDINGS_INSTRUCTION)
  for f in ${log_files};
  do
    ((_i++))
    if [ -f "${f}" ]; then
      if ! grep -q -E "^\s*${f}\s*\{\s*$" /usr/bin/logrotate.d/logrotate.conf; then
        output "Found new file $f, Processing..."
        file_owner_user=$(stat -c %U ${f})
        file_owner_group=$(stat -c %G ${f})
        if [ "$file_owner_user" != "UNKNOWN" ] && [ "$file_owner_group" != "UNKNOWN" ]; then
          unset new_log
          new_log="${f} {"
          new_log="${new_log}\n  su ${file_owner_user} ${file_owner_group}"
          new_log="${new_log}\n  copytruncate"
          new_log="${new_log}\n  rotate ${logrotate_copies}"
          new_log="${new_log}\n  missingok"
          if [ -n "${logrotate_logfile_compression}" ]; then
            new_log="${new_log}\n  ${logrotate_logfile_compression}"
          fi
          if [ -n "${logrotate_logfile_compression_delay}" ]; then
            new_log="${new_log}\n  ${logrotate_logfile_compression_delay}"
          fi
          if [ -n "${logrotate_interval}" ]; then
            new_log="${new_log}\n  ${logrotate_interval}"
          fi
          if [ -n "${logrotate_size}" ]; then
            new_log="${new_log}\n  ${logrotate_size}"
          fi
          if [ -n "${LOGROTATE_DATEFORMAT}" ]; then
            new_log="${new_log}\n  dateext\n  dateformat ${LOGROTATE_DATEFORMAT}"
          fi
          new_log="${new_log}\n}"
          echo "Inserting new ${f} in alphabetic order to /usr/bin/logratate.d/logrotate.conf"

          insertInOrder "$new_log" "$log_files" /usr/bin/logrotate.d/logrotate.conf $last_line_no $d ${_i}
        else
          output "File has unknown user or group: ${f}, user: ${file_owner_user}, group: ${file_owner_group}"
        fi
      fi
    else
      remove $f /usr/bin/logrotate.d/logrotate.conf
    fi
  done

  # remove config in /usr/bin/logrotate.d/logrotate.conf that no longer exists
  configs=$(grep -E "^\s*${d}.*\{\s*$" /usr/bin/logrotate.d/logrotate.conf | cut -f1 -d' ')

  for c in $configs; do
    if [ ! -f "${c}" ]; then
      remove $c /usr/bin/logrotate.d/logrotate.conf
    fi
  done

  last_line_no=$(awk "
    BEGIN {}
      /^ *${_d}.*\{ *$/ {banner = 1; printf NR \" \"; print; next}
      /^ *} *$/ {if (banner) {printf NR \" \"; print}; banner = 0}
      {if (banner) {printf NR \" \"; print }}
    END {}
  " /usr/bin/logrotate.d/logrotate.conf)
  last_line_no=$(($(echo "${last_line_no}" | tail -n 1 | cut -f1 -d' ') + 1))
done

# ----- Take all Log in Subfolders ------

all_log_dirs=""

if [ -n "${ALL_LOGS_DIRECTORIES}" ]; then
  all_log_dirs=${ALL_LOGS_DIRECTORIES}
fi

for d in ${all_log_dirs}
do
  unset _d
  _d=${_d//\//\\/}
  _i=-1
  log_files=$(find ${d} -type f);
  for f in ${log_files};
  do
    ((_i++))
    if [ -f "${f}" ]; then
      if ! grep -q -E "^\s*${f}\s*\{\s*$" /usr/bin/logrotate.d/logrotate.conf; then
        output "Found new file $f, Processing..."
        file_owner_user=$(stat -c %U ${f})
        file_owner_group=$(stat -c %G ${f})
        if [ "$file_owner_user" != "UNKNOWN" ] && [ "$file_owner_group" != "UNKNOWN" ]; then
          unset new_log
          new_log="${f} {"
          new_log="${new_log}\n  su ${file_owner_user} ${file_owner_group}"
          new_log="${new_log}\n  copytruncate"
          new_log="${new_log}\n  rotate ${logrotate_copies}"
          new_log="${new_log}\n  missingok"
          if [ -n "${logrotate_logfile_compression}" ]; then
            new_log="${new_log}\n  ${logrotate_logfile_compression}"
          fi
          if [ -n "${logrotate_logfile_compression_delay}" ]; then
            new_log="${new_log}\n  ${logrotate_logfile_compression_delay}"
          fi
          if [ -n "${logrotate_interval}" ]; then
            new_log="${new_log}\n  ${logrotate_interval}"
          fi
          if [ -n "${logrotate_size}" ]; then
            new_log="${new_log}\n  ${logrotate_size}"
          fi
          if [ -n "${LOGROTATE_DATEFORMAT}" ]; then
            new_log="${new_log}\n  dateext\n  dateformat ${LOGROTATE_DATEFORMAT}"
          fi
          new_log="${new_log}\n}"
          echo "Inserting new ${f} in alphabetic order to /usr/bin/logratate.d/logrotate.conf"

          insertInOrder "$new_log" "$log_files" /usr/bin/logrotate.d/logrotate.conf $last_line_no $d ${_i}
        else
          output "File has unknown user or group: ${f}, user: ${file_owner_user}, group: ${file_owner_group}"
        fi
      fi
    else
      remove $f /usr/bin/logrotate.d/logrotate.conf
    fi
  done

  # remove config in /usr/bin/logrotate.d/logrotate.conf that no longer exists
  configs=$(grep -E "^\s*${d}.*\{\s*$" /usr/bin/logrotate.d/logrotate.conf | cut -f1 -d' ')

  for c in $configs; do
    if [ ! -f "${c}" ]; then
      remove $c /usr/bin/logrotate.d/logrotate.conf
    fi
  done

  last_line_no=$(awk "
    BEGIN {}
      /^ *${_d}.*\{ *$/ {banner = 1; printf NR \" \"; print; next}
      /^ *} *$/ {if (banner) {printf NR \" \"; print}; banner = 0}
      {if (banner) {printf NR \" \"; print }}
    END {}
  " /usr/bin/logrotate.d/logrotate.conf)
  last_line_no=$(($(echo "${last_line_no}" | tail -n 1 | cut -f1 -d' ') + 1))
done
