#!/bin/bash

set -e

HADOOP_VERSION="3.4.2"
HADOOP_HOME="/opt/hadoop"
HADOOP_ARCHIVE="/tmp/hadoop-${HADOOP_VERSION}.tar.gz"
HADOOP_URL="https://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz"

echo "=== Installing Java ==="

apt-get update
apt-get install -y openjdk-17-jdk wget

echo "=== Installing Hadoop ${HADOOP_VERSION} ==="

if [ ! -d "/opt/hadoop-${HADOOP_VERSION}" ]; then
    wget -O "${HADOOP_ARCHIVE}" "${HADOOP_URL}"
    tar -xzf "${HADOOP_ARCHIVE}" -C /opt
fi

ln -sfn "/opt/hadoop-${HADOOP_VERSION}" "${HADOOP_HOME}"

echo "=== Setting environment ==="

cat > /etc/profile.d/hadoop.sh <<EOF
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export HADOOP_HOME=/opt/hadoop
export HADOOP_CONF_DIR=\$HADOOP_HOME/etc/hadoop
export PATH=\$PATH:\$HADOOP_HOME/bin:\$HADOOP_HOME/sbin
EOF

source /etc/profile.d/hadoop.sh

echo "=== Hadoop version ==="

hadoop version

echo "=== Installation completed ==="
