#!/bin/bash

set -e

echo "=== Starting HDFS cluster ==="

start-dfs.sh

echo
echo "=== Running Hadoop processes ==="

jps

echo
echo "=== Cluster started ==="
