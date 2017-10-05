#!/usr/bin/env bash

set -x
set -e

# source: https://coderwall.com/p/dtwc1q/insecure-and-self-signed-private-docker-registry-with-boot2docker

_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

DOCKER_MACHINE_NAME="local-mesos-cluster"

# Specify where we will install
# the xip.io certificate
SSL_DIR="./certs"

DOCKER_IP=$(echo ${DOCKER_HOST:-tcp://127.0.0.1:2376} | cut -d/ -f3 | cut -d: -f1)

# to be used as registry domain
FLOATING_IP="${DOCKER_IP}"

# domain we're creating cert for
DOMAIN="${FLOATING_IP}.xip.io"

# A blank passphrase
PASSPHRASE=""

# Set our CSR variables
SUBJ="
C=US
ST=Connecticut
O=
localityName=New Haven
commonName=$DOMAIN
organizationalUnitName=
emailAddress=
"

# Create our SSL directory
# in case it doesn't exist
mkdir -p "${_DIR}/../${SSL_DIR}"

# Generate our Private Key, CSR and Certificate
# openssl genrsa -out "${_DIR}/../${SSL_DIR}/xip.io.key" 4096
# openssl req -new -subj "$(echo -n "$SUBJ" | tr "\n" "/")" -key "${_DIR}/../${SSL_DIR}/xip.io.key" -out "${_DIR}/../${SSL_DIR}/xip.io.csr" -passin pass:$PASSPHRASE
# openssl x509 -req -days 365 -in "${_DIR}/../${SSL_DIR}/xip.io.csr" -signkey "${_DIR}/../${SSL_DIR}/xip.io.key" -out "${_DIR}/../${SSL_DIR}/xip.io.crt"


openssl req \
  -newkey rsa:4096 -nodes -sha256 \
  -subj "$(echo -n "$SUBJ" | tr "\n" "/")" \
  -keyout ${_DIR}/../${SSL_DIR}/domain.key \
  -x509 -days 356 \
  -out ${_DIR}/../${SSL_DIR}/domain.crt

docker-machine scp ${_DIR}/../${SSL_DIR}/domain.key $DOCKER_MACHINE_NAME:.
docker-machine scp ${_DIR}/../${SSL_DIR}/domain.crt $DOCKER_MACHINE_NAME:.


docker-machine ssh $DOCKER_MACHINE_NAME sudo mkdir -p /etc/docker/certs.d/${FLOATING_IP}.xip.io:5000
docker-machine ssh $DOCKER_MACHINE_NAME sudo mv -v /home/docker/domain.* /etc/docker/certs.d/${FLOATING_IP}.xip.io:5000/

# FIXME: these vars need to be fixed for sure

_TEMP_CONFIG_FILE=$(uuidgen)

# add to array
jq '.HostOptions.EngineOptions.InsecureRegistry[.HostOptions.EngineOptions.InsecureRegistry| length] |= . + "192.168.99.101.xip.io:5000"' ~/.docker/machine/machines/$DOCKER_MACHINE_NAME/config.json > ~/.docker/machine/machines/$DOCKER_MACHINE_NAME/config-${_TEMP_CONFIG_FILE}.json

# verify it exists in there
\cat ~/.docker/machine/machines/$DOCKER_MACHINE_NAME/config-${_TEMP_CONFIG_FILE}.json | jq '.HostOptions.EngineOptions.InsecureRegistry' | jq 'contains(["192.168.99.101.xip.io:5000"])'

# jq '.HostOptions.EngineOptions.InsecureRegistry as $f | "orange" | IN($f[])' ~/.docker/machine/machines/$DOCKER_MACHINE_NAME/config.json

# FIXME: This has to be broken
# if this is null, exit
RET_VALUE=$(jq '.HostOptions.EngineOptions.InsecureRegistry | index( "192.168.99.101.xip.io:5000" )' ~/.docker/machine/machines/$DOCKER_MACHINE_NAME/config-${_TEMP_CONFIG_FILE}.json)

if [[ "${RET_VALUE}" = "null" ]]; then
  # FIXME: Use bash variables for these
  # FIXME: should be pointing to the uuid version of config.json
  echo "sorry, 192.168.99.101.xip.io:5000 is not part of the InsecureRegistry array in ~/.docker/machine/machines/$DOCKER_MACHINE_NAME/config.json)"
  \cat ~/.docker/machine/machines/$DOCKER_MACHINE_NAME/config.json | jq
  exit 1
else
  echo "atomic mover file now"
  mv -fv ~/.docker/machine/machines/$DOCKER_MACHINE_NAME/config-${_TEMP_CONFIG_FILE}.json ~/.docker/machine/machines/$DOCKER_MACHINE_NAME/config.json
fi

