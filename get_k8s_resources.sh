#!/bin/bash

# Function to display usage
usage() {
    echo "Usage: $0 --namespaces <namespace1,namespace2,...> --resource_types <resource1,resource2,...>"
    exit 1
}

# Parse named parameters
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --namespaces) namespaces="$2"; shift ;;
        --resource_types) resource_types="$2"; shift ;;
        *) usage ;;
    esac
    shift
done

# Check if both parameters are provided
if [ -z "$namespaces" ] || [ -z "$resource_types" ]; then
    usage
fi

# Directory to save the YAML files
OUTPUT_DIR="k8s_resources"
mkdir -p $OUTPUT_DIR

# Convert comma-separated strings to arrays
IFS=',' read -r -a namespace_array <<< "$namespaces"
IFS=',' read -r -a resource_type_array <<< "$resource_types"

# Loop through each namespace
for ns in "${namespace_array[@]}"; do
    # Create a directory for the namespace
    ns_dir="$OUTPUT_DIR/$ns"
    mkdir -p $ns_dir

    # Loop through each resource type
    for resource in "${resource_type_array[@]}"; do
        # Skip secrets resource type
        if [ "$resource" == "secrets" ]; then
            continue
        fi

        # Get all resources of this type in the namespace
        if [ "$resource" == "replicaset" ]; then
            # Exclude inactive ReplicaSets
            resources=$(kubectl get $resource --namespace $ns -o jsonpath='{range .items[?(@.status.replicas==@.status.readyReplicas)]}{.metadata.name}{"\n"}{end}')
        elif [ "$resource" == "deployment" ]; then
            # Exclude inactive Deployments
            resources=$(kubectl get $resource --namespace $ns -o jsonpath='{range .items[?(@.status.replicas>0)]}{.metadata.name}{"\n"}{end}')
        else
            resources=$(kubectl get $resource --namespace $ns -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')
        fi

        # Loop through each resource and save to a separate YAML file
        for res in $resources; do
            kubectl get $resource $res --namespace $ns -o yaml > "$ns_dir/${resource}_${res}.yaml"
        done
    done
done

echo "All resources have been saved to $OUTPUT_DIR"