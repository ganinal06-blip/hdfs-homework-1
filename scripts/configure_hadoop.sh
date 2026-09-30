#!/bin/bash

set -e

HADOOP_HOME="/opt/hadoop"
CONFIG_DIR="$HADOOP_HOME/etc/hadoop"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=== Configuring Hadoop ==="

cp "$PROJECT_DIR/config/core-site.xml" "$CONFIG_DIR/core-site.xml"
cp "$PROJECT_DIR/config/hdfs-site.xml" "$CONFIG_DIR/hdfs-site.xml"
cp "$PROJECT_DIR/config/workers" "$CONFIG_DIR/workers"
cp "$PROJECT_DIR/config/hadoop-env.sh" "$CONFIG_DIR/hadoop-env.sh"

echo "=== Creating HDFS directories ==="

mkdir -p /data/hdfs/namenode
mkdir -p /data/hdfs/datanode

echo "=== Setting permissions ==="

chown -R team:team /data/hdfs

echo "=== Configuration completed ==="
