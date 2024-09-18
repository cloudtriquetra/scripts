#!/bin/bash

# Directory to save the YAML files
OUTPUT_DIR="k8s_resources"
mkdir -p $OUTPUT_DIR

# Get all namespaces
namespaces=$(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}')

# Loop through each namespace
for ns in $namespaces; do
    # Create a directory for the namespace
    ns_dir="$OUTPUT_DIR/$ns"
    mkdir -p $ns_dir

    # Get all resource types in the namespace
    resource_types=$(kubectl api-resources --verbs=list --namespaced -o name)

    # Loop through each resource type
    for resource in $resource_types; do
        # Get all resources of this type in the namespace
        resources=$(kubectl get $resource --namespace $ns -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')

        # Loop through each resource and save to a separate YAML file
        for res in $resources; do
            kubectl get $resource $res --namespace $ns -o yaml > "$ns_dir/${resource}_${res}.yaml"
        done
    done
done

echo "All resources have been saved to $OUTPUT_DIR"
