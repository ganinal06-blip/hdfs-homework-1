#!/bin/bash

set -e

echo "========================================"
echo "WARNING"
echo "========================================"
echo "NameNode formatting will erase existing"
echo "NameNode metadata."
echo
echo "This script must be executed ONLY when"
echo "creating a new HDFS cluster."
echo "========================================"

read -p "Continue? Type FORMAT: " CONFIRM

if [ "$CONFIRM" != "FORMAT" ]; then
    echo "Formatting cancelled."
    exit 0
fi

echo "=== Formatting NameNode ==="

hdfs namenode -format

echo "=== NameNode formatting completed ==="
