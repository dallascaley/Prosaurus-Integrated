#!/bin/bash
# Read the join command from the file
JOIN_COMMAND=$(cat /tmp/join_command.txt)

# Join the worker node to the Kubernetes cluster
echo "Joining the worker node to the cluster..."
$JOIN_COMMAND
