#!/bin/bash

#############################################################################################################
#
# Author: Brian Bianco (brian.bianco@gmail.com)
#
# License: Apache License, Version 2.0, http://www.apache.org/licenses/LICENSE-2.0.html
#
# Description: Simple utility to attempt to check if all devices from $glob are trapping processes in D state
#
# Usage:   drivecheck.sh [device] [additional device(s)]
#
#############################################################################################################

duration=${SLEEP_TIME:-4}

test_drive ()
{
  file -s $1 &
  file_pid=$!
  sleep $duration
  if [ -e /proc/$file_pid/stat ]; then
    process_status=`cut -d ' ' -f 3 /proc/$file_pid/stat`
  else
    process_status="N"
  fi
}
glob=/dev/sd*


declare -A results


for drive in $glob; do
    test_drive $drive
    case $process_status in
      "S")
        echo "Proccess is in interruptible sleep"
        results[$drive]=0
        ;;
      "D")
        echo "Process is stuck in uninterruptible sleep:" $drive 1>&2
        results[$drive]=1
        ;;
      "R")
        echo "Process is running normally"
        results[$drive]=0
        ;;
      "T")
        echo "Process is in stopped state"
        results[$drive]=0
        ;;
      "Z")
        echo "Process is a zombie.....get your shotgun"
        results[$drive]=0
        ;;
      "N")
        echo "Process is no longer running"
        results[$drive]=0
        ;;
      * )
        echo "Process is in unknown state: " $process_status ":" $drive 1>&2
        results[$drive]=1
        ;;
    esac
done

exit_status=0
for i in "${!results[@]}"; do
  echo "drive: "$i" results: "${results[$i]}
  if [ ${results[$i]} -gt 0 ]; then
    exit_status=$(($exit_status + 1))
  fi
done

if [ $exit_status -gt 0 ]; then echo $exit_status "failed ephemeral drives" 1>&2; fi
exit $exit_status


