#!/usr/bin/env bash

# use this on a digitalocean server ( for example )

# source: https://github.com/autra/dotFiles/blob/dce36edf491410eede49d5bd460d3678bf66caf1/.aliases
export HOST_IP=$(curl ipv4.icanhazip.com 2>/dev/null)
export DOCKER_IP=$HOST_IP
export DOCKER_HOST="tcp://${DOCKER_IP}:2377"
export PATH_TO_DOCKER=$(which docker)
export YOUR_HOSTNAME=$(hostname | cut -d "." -f1 | awk '{print $1}')

echo "******************************************"
echo "HOST_IP: ${HOST_IP}"
echo "DOCKER_IP: ${DOCKER_IP}"
echo "DOCKER_HOST: ${DOCKER_HOST}"
echo "PATH_TO_DOCKER: ${PATH_TO_DOCKER}"
echo "YOUR_HOSTNAME: ${YOUR_HOSTNAME}"
echo "******************************************"

# unset HOST_IP
# unset DOCKER_IP
# unset DOCKER_HOST
