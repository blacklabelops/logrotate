#!/bin/bash
#
# Creation of Logfile

function handleSingleFile() {
  local singleFile="$1"
  local file_owner_user=$(stat -c %U ${singleFile})
  local file_owner_group=$(stat -c %G ${singleFile})
  local new_logrotate_entry=$(createLogrotateConfigurationEntry "${singleFile}" "${file_owner_user}" "${file_owner_group}" "${logrotate_copies}" "${logrotate_logfile_compression}" "${logrotate_logfile_compression_delay}" "${logrotate_mode}" "${logrotate_interval}" "${logrotate_size}" "${logrotate_dateformat}" "${logrotate_minsize}" "${logrotate_maxage}" "${logrotate_prerotate}" "${logrotate_postrotate}" "${logrotate_lastaction}")
  echo "Inserting new ${singleFile} to /usr/bin/logrotate.d/logrotate.conf"
  insertConfigurationEntry "$new_logrotate_entry" "/usr/bin/logrotate.d/logrotate.conf"
}

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

# Check if regex search is enabled
if [ -n "${LOGS_FILE_REGEX}" ]; then
  if [ "$COUNTER" -eq "0" ]; then
    LOGS_FILE_ENDINGS_INSTRUCTION="-regex $LOGS_FILE_REGEX"
  else
    LOGS_FILE_ENDINGS_INSTRUCTION="$LOGS_FILE_ENDINGS_INSTRUCTION -o -regex $LOGS_FILE_REGEX"
  fi
fi

for d in ${log_dirs}
do
  log_files=$(find ${d} -type f $LOGS_FILE_ENDINGS_INSTRUCTION) || continue
  for f in ${log_files};
  do
    if [ -f "${f}" ]; then
      echo "Found new file $f, Processing..."
      handleSingleFile "$f"
    fi
  done
done

# ----- Take all Log in Subfolders ------

all_log_dirs=""

if [ -n "${ALL_LOGS_DIRECTORIES}" ]; then
  all_log_dirs=${ALL_LOGS_DIRECTORIES}
fi

for d in ${all_log_dirs}
do
  log_files=$(find ${d} -type f);
  for f in ${log_files};
  do
    if [ -f "${f}" ]; then
      echo "Found new file $f, Processing..."
      handleSingleFile "$f"
    fi
  done
done

cat /usr/bin/logrotate.d/logrotate.conf
