#!/bin/bash

echo "========================================"
echo "        HDFS CLUSTER CHECK"
echo "========================================"

echo
echo "=== Hadoop version ==="
hadoop version | head -n 1

echo
echo "=== Running Hadoop processes ==="
jps

echo
echo "=== HDFS report ==="
hdfs dfsadmin -report

echo
echo "=== Filesystem check ==="
hdfs fsck / -files -blocks -locations

echo
echo "=== Checking critical errors in logs ==="

LOG_DIR="/opt/hadoop/logs"

if [ -d "$LOG_DIR" ]; then

    ERRORS=$(grep -Ei "FATAL|ERROR" "$LOG_DIR"/* 2>/dev/null | \
       grep -vi "received signal 15" | \
       head -20 || true)

    if [ -z "$ERRORS" ]; then
        echo "No critical errors found."
    else
        echo "Possible critical errors:"
        echo "$ERRORS"
    fi

else
    echo "Hadoop log directory not found."
fi

echo
echo "========================================"
echo "        END OF CLUSTER CHECK"
echo "========================================"
