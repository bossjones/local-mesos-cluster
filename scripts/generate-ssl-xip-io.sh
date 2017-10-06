#!/usr/bin/env bash

# source: https://serversforhackers.com/c/self-signed-ssl-certificates

_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Specify where we will install
# the xip.io certificate
SSL_DIR="./certs"

# Set the wildcarded domain
# we want to use
DOMAIN="*.xip.io"

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
openssl genrsa -out "${_DIR}/../${SSL_DIR}/xip.io.key" 4096
openssl req -new -subj "$(echo -n "$SUBJ" | tr "\n" "/")" -key "${_DIR}/../${SSL_DIR}/xip.io.key" -out "${_DIR}/../${SSL_DIR}/xip.io.csr" -passin pass:$PASSPHRASE
openssl x509 -req -days 365 -in "${_DIR}/../${SSL_DIR}/xip.io.csr" -signkey "${_DIR}/../${SSL_DIR}/xip.io.key" -out "${_DIR}/../${SSL_DIR}/xip.io.crt"
