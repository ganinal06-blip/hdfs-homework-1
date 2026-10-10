#!/bin/bash
set -e

NN_HOST="team-12-nn"
DATANODES=("team-12-en" "team-12-00" "team-12-01")
ALL_NODES=("$NN_HOST" "${DATANODES[@]}")

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "check ssh..."
for HOST in "${DATANODES[@]}"; do
  echo "$HOST"
  ssh "$HOST" hostname
done

if jps 2>/dev/null | grep -qw "NameNode"; then
  echo "namenode already running"
  RUNNING=true
else
  echo "namenode stopped"
  RUNNING=false
fi

if [ "$RUNNING" = false ]; then
  for HOST in "${ALL_NODES[@]}"; do
    echo "setup $HOST"
    if [ "$HOST" = "$NN_HOST" ]; then
      if [ ! -x "/opt/hadoop/bin/hadoop" ]; then
        sudo bash "$PROJECT_DIR/scripts/install_hadoop.sh"
      fi
      sudo bash "$PROJECT_DIR/scripts/configure_hadoop.sh"
    else
      if ! ssh "$HOST" "test -x /opt/hadoop/bin/hadoop"; then
        scp "$PROJECT_DIR/scripts/install_hadoop.sh" "$HOST:/tmp/install_hadoop.sh"
        ssh "$HOST" "sudo bash /tmp/install_hadoop.sh"
      fi
      scp "$PROJECT_DIR/config/core-site.xml" "$HOST:/tmp/core-site.xml"
      scp "$PROJECT_DIR/config/hdfs-site.xml" "$HOST:/tmp/hdfs-site.xml"
      scp "$PROJECT_DIR/config/workers" "$HOST:/tmp/workers"
      scp "$PROJECT_DIR/config/hadoop-env.sh" "$HOST:/tmp/hadoop-env.sh"
      ssh "$HOST" "sudo cp /tmp/core-site.xml /tmp/hdfs-site.xml /tmp/workers /tmp/hadoop-env.sh /opt/hadoop/etc/hadoop/"
      ssh "$HOST" "sudo mkdir -p /data/hdfs/namenode /data/hdfs/datanode && sudo chown -R team:team /data/hdfs"
    fi
  done
else
  echo "cluster already running, skip install"
fi

source /etc/profile.d/hadoop.sh

if [ ! -f "/data/hdfs/namenode/current/VERSION" ]; then
  echo "namenode not formatted"
  read -p "format? type FORMAT: " CONFIRM
  if [ "$CONFIRM" = "FORMAT" ]; then
    bash "$PROJECT_DIR/scripts/format_namenode.sh"
  else
    echo "skip format, exit"
    exit 0
  fi
fi

LIVE=$(hdfs dfsadmin -report 2>/dev/null | awk '/Live datanodes/ {gsub(/[():]/, "", $3); print $3}')
if [ "$LIVE" = "3" ]; then
  echo "3 datanodes live, skip start"
else
  echo "live: ${LIVE:-0}, starting..."
  bash "$PROJECT_DIR/scripts/start_cluster.sh"
fi

bash "$PROJECT_DIR/scripts/check_cluster.sh"
echo "done"
