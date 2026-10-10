#!/bin/bash

echo "version:"
hadoop version | head -n 1
echo

echo "processes:"
jps
echo

echo "hdfs report:"
hdfs dfsadmin -report
echo

echo "fsck:"
hdfs fsck / -files -blocks -locations
echo

echo "logs check:"
LOG_DIR="/opt/hadoop/logs"
if [ -d "$LOG_DIR" ]; then
  ERRORS=$(grep -Ei "FATAL|ERROR" "$LOG_DIR"/* 2>/dev/null | grep -vi "received signal 15" | head -20 || true)
  if [ -z "$ERRORS" ]; then
    echo "no errors"
  else
    echo "$ERRORS"
  fi
else
  echo "no log dir"
fi
