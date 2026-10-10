#!/bin/bash
set -e

echo "WARNING: format erases namenode metadata"
echo "run this only for a new cluster"

hdfs namenode -format
echo "done"
