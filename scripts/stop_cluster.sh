#!/bin/bash

set -e

echo "=== Stopping HDFS cluster ==="

stop-dfs.sh

echo
echo "=== Remaining Hadoop processes ==="

jps

echo
echo "=== Cluster stopped ==="
