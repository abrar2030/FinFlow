#!/bin/bash

# Script to initialize Kafka and Zookeeper
# Usage: ./init-kafka.sh

set -e

KAFKA_CONFIG_DIR=${KAFKA_CONFIG_DIR:-"../config"}
KAFKA_BIN=${KAFKA_HOME:-"/opt/kafka"}/bin
ZOOKEEPER_PROPERTIES="$KAFKA_CONFIG_DIR/zookeeper.properties"
SERVER_PROPERTIES="$KAFKA_CONFIG_DIR/server.properties"

# Check if configuration files exist
if [ ! -f "$ZOOKEEPER_PROPERTIES" ]; then
  echo "Error: Zookeeper properties file not found at $ZOOKEEPER_PROPERTIES"
  exit 1
fi

if [ ! -f "$SERVER_PROPERTIES" ]; then
  echo "Error: Server properties file not found at $SERVER_PROPERTIES"
  exit 1
fi

# Start Zookeeper
echo "Starting Zookeeper..."
$KAFKA_BIN/zookeeper-server-start.sh -daemon $ZOOKEEPER_PROPERTIES
sleep 5

# Check if Zookeeper started successfully
if ! nc -z localhost 2181; then
  echo "Error: Zookeeper failed to start"
  exit 1
fi
echo "Zookeeper started successfully"

# Start Kafka
echo "Starting Kafka broker..."
$KAFKA_BIN/kafka-server-start.sh -daemon $SERVER_PROPERTIES
sleep 10

# Check if Kafka started successfully
if ! nc -z localhost 9092; then
  echo "Error: Kafka broker failed to start"
  exit 1
fi
echo "Kafka broker started successfully"

# Create topics
echo "Creating Kafka topics..."
./create-topics.sh "$KAFKA_CONFIG_DIR/topics.json"

echo "Kafka initialization completed successfully"
