#!/bin/bash

set -e

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
echo "=== SSH connection check completed ==="

echo
echo "=== Checking current cluster state ==="

if jps | grep -q "NameNode"; then
    echo "NameNode is already running."
    CLUSTER_ALREADY_RUNNING=true
else
    echo "NameNode is not running."
    CLUSTER_ALREADY_RUNNING=false
fi

echo

if [ "$CLUSTER_ALREADY_RUNNING" = false ]; then

    echo "=== Installing and configuring Hadoop ==="

    for HOST in "${ALL_NODES[@]}"; do

        echo
        echo "----------------------------------------"
        echo "Processing: $HOST"
        echo "----------------------------------------"

        if [ "$HOST" = "$NN_HOST" ]; then

            if [ -x "/opt/hadoop/bin/hadoop" ]; then
                echo "Hadoop is already installed on $HOST."
            else
                echo "Installing Hadoop on $HOST..."
                sudo bash "$PROJECT_DIR/scripts/install_hadoop.sh"
            fi

            echo "Configuring Hadoop on $HOST..."
            sudo bash "$PROJECT_DIR/scripts/configure_hadoop.sh"

        else

            if ssh "$HOST" "test -x /opt/hadoop/bin/hadoop"; then
                echo "Hadoop is already installed on $HOST."
            else
                echo "Installing Hadoop on $HOST..."

                scp "$PROJECT_DIR/scripts/install_hadoop.sh" \
                    "$HOST:/tmp/install_hadoop.sh"

                ssh "$HOST" "sudo bash /tmp/install_hadoop.sh"
            fi

            echo "Configuring Hadoop on $HOST..."

            scp "$PROJECT_DIR/config/core-site.xml" \
                "$HOST:/tmp/core-site.xml"

            scp "$PROJECT_DIR/config/hdfs-site.xml" \
                "$HOST:/tmp/hdfs-site.xml"

            scp "$PROJECT_DIR/config/workers" \
                "$HOST:/tmp/workers"

            scp "$PROJECT_DIR/config/hadoop-env.sh" \
                "$HOST:/tmp/hadoop-env.sh"

            ssh "$HOST" "sudo cp /tmp/core-site.xml /opt/hadoop/etc/hadoop/core-site.xml"
            ssh "$HOST" "sudo cp /tmp/hdfs-site.xml /opt/hadoop/etc/hadoop/hdfs-site.xml"
            ssh "$HOST" "sudo cp /tmp/workers /opt/hadoop/etc/hadoop/workers"
            ssh "$HOST" "sudo cp /tmp/hadoop-env.sh /opt/hadoop/etc/hadoop/hadoop-env.sh"

            ssh "$HOST" "sudo mkdir -p /data/hdfs/namenode /data/hdfs/datanode"
            ssh "$HOST" "sudo chown -R team:team /data/hdfs"

        fi

    done

    echo
    echo "=== Hadoop installation and configuration completed ==="

else

    echo "=== Existing running cluster detected ==="
    echo "Installation and configuration will not be changed."

fi

echo
echo "=== Checking NameNode state ==="

if [ -f "/data/hdfs/namenode/current/VERSION" ]; then

    echo "Existing NameNode metadata found."
    echo "Formatting is not required."

else

    echo "NameNode metadata not found."
    echo
    echo "This appears to be a new HDFS cluster."
    read -p "Format NameNode? Type FORMAT to continue: " CONFIRM

    if [ "$CONFIRM" = "FORMAT" ]; then
        sudo bash "$PROJECT_DIR/scripts/format_namenode.sh"
    else
        echo "NameNode formatting skipped."
        echo "Run format_namenode.sh before starting a new cluster."
        exit 0
    fi

fi

echo
echo "=== Checking DataNode state ==="

LIVE_DATANODES=$(hdfs dfsadmin -report 2>/dev/null | \
    awk '/Live datanodes/ {gsub(/[()]/, "", $3); print $3}')

if [ "$LIVE_DATANODES" = "3" ]; then

    echo "All 3 DataNodes are already live."
    echo "HDFS start is not required."

else

    echo "Live DataNodes: ${LIVE_DATANODES:-0}"
    echo "Starting HDFS cluster..."

    bash "$PROJECT_DIR/scripts/start_cluster.sh"

fi

echo
echo "=== Checking cluster ==="

bash "$PROJECT_DIR/scripts/check_cluster.sh"

echo
echo "========================================"
echo "       DEPLOYMENT COMPLETED"
echo "========================================"
