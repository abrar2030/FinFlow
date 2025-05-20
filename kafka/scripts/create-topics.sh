#!/bin/bash

# Script to create Kafka topics from the topics.json configuration file
# Usage: ./create-topics.sh <path-to-topics-json>

set -e

TOPICS_JSON=${1:-"../config/topics.json"}
KAFKA_BIN=${KAFKA_HOME:-"/opt/kafka"}/bin
BOOTSTRAP_SERVERS=${BOOTSTRAP_SERVERS:-"localhost:9092"}

# Check if topics.json exists
if [ ! -f "$TOPICS_JSON" ]; then
  echo "Error: Topics configuration file not found at $TOPICS_JSON"
  exit 1
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
  echo "Error: jq is required but not installed. Please install jq."
  exit 1
fi

echo "Creating Kafka topics from $TOPICS_JSON..."

# Read topics from JSON and create them
jq -c '.[]' "$TOPICS_JSON" | while read -r topic_json; do
  name=$(echo "$topic_json" | jq -r '.name')
  partitions=$(echo "$topic_json" | jq -r '.partitions')
  replication_factor=$(echo "$topic_json" | jq -r '.replication_factor')
  
  echo "Creating topic: $name with $partitions partitions and replication factor $replication_factor"
  
  # Build the command with configs if they exist
  create_cmd="$KAFKA_BIN/kafka-topics.sh --create --bootstrap-server $BOOTSTRAP_SERVERS --topic $name --partitions $partitions --replication-factor $replication_factor"
  
  # Add configs if they exist
  configs=$(echo "$topic_json" | jq -r '.configs | to_entries | map("--config \(.key)=\(.value|tostring)") | join(" ")')
  if [ -n "$configs" ]; then
    create_cmd="$create_cmd $configs"
  fi
  
  # Execute the command
  echo "Executing: $create_cmd"
  eval "$create_cmd" || echo "Warning: Failed to create topic $name, it might already exist."
done

echo "Topic creation completed."
