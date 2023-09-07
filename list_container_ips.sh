#!/bin/bash

# Get a list of all running containers
container_ids=$(docker ps -q)

# Loop through each container and display its IP address
for container_id in $container_ids; do
    container_name=$(docker inspect -f '{{ .Name }}' $container_id)
    container_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $container_id)
    echo "Container Name: $container_name, IP Address: $container_ip"
done
