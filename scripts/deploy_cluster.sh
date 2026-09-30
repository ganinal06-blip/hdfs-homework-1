#!/bin/bash

set -e

HADOOP_VERSION="3.4.2"

NN_HOST="team-12-nn"
DATANODES=("team-12-en" "team-12-00" "team-12-01")
ALL_NODES=("$NN_HOST" "${DATANODES[@]}")

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "========================================"
echo "       HDFS CLUSTER DEPLOYMENT"
echo "========================================"

echo
echo "=== Checking SSH connection ==="

for HOST in "${DATANODES[@]}"; do
    echo "Checking $HOST..."
    ssh "$HOST" hostname
done

echo
echo "=== Checking local host ==="
hostname

echo
echo "=== Installing and configuring Hadoop ==="

for HOST in "${ALL_NODES[@]}"; do

    echo
    echo "----------------------------------------"
    echo "Processing: $HOST"
    echo "----------------------------------------"

    if [ "$HOST" = "$NN_HOST" ]; then

        echo "Installing Hadoop locally..."

        sudo bash "$PROJECT_DIR/scripts/install_hadoop.sh"
        sudo bash "$PROJECT_DIR/scripts/configure_hadoop.sh"

    else

        echo "Installing Hadoop on $HOST..."

        scp "$PROJECT_DIR/scripts/install_hadoop.sh" \
            "$HOST:/tmp/install_hadoop.sh"

        scp "$PROJECT_DIR/config/core-site.xml" \
            "$HOST:/tmp/core-site.xml"

        scp "$PROJECT_DIR/config/hdfs-site.xml" \
            "$HOST:/tmp/hdfs-site.xml"

        scp "$PROJECT_DIR/config/workers" \
            "$HOST:/tmp/workers"

        scp "$PROJECT_DIR/config/hadoop-env.sh" \
            "$HOST:/tmp/hadoop-env.sh"

        ssh "$HOST" "sudo bash /tmp/install_hadoop.sh"

        ssh "$HOST" "sudo mkdir -p /opt/hadoop/etc/hadoop"
        ssh "$HOST" "sudo cp /tmp/core-site.xml /opt/hadoop/etc/hadoop/core-site.xml"
        ssh "$HOST" "sudo cp /tmp/hdfs-site.xml /opt/hadoop/etc/hadoop/hdfs-site.xml"
        ssh "$HOST" "sudo cp /tmp/workers /opt/hadoop/etc/hadoop/workers"
        ssh "$HOST" "sudo cp /tmp/hadoop-env.sh /opt/hadoop/etc/hadoop/hadoop-env.sh"

        ssh "$HOST" "sudo mkdir -p /data/hdfs/namenode /data/hdfs/datanode"
        ssh "$HOST" "sudo chown -R team:team /data/hdfs"

    fi

done

echo
echo "=== Hadoop deployment completed ==="

echo
echo "IMPORTANT:"
echo "If this is a new cluster, format the NameNode before starting HDFS."
echo
echo "Run:"
echo "  sudo bash scripts/format_namenode.sh"
echo
echo "Then:"
echo "  bash scripts/start_cluster.sh"

echo
echo "========================================"
echo "       DEPLOYMENT FINISHED"
echo "========================================"
