#!/usr/bin/env sh

set -x
set -e

# source: https://coderwall.com/p/dtwc1q/insecure-and-self-signed-private-docker-registry-with-boot2docker

export DOCKER_MACHINE_NAME="local-mesos-cluster"

cd $HOME

# Specify where we will install
# the xip.io certificate
export SSL_DIR="./certs"

export DOCKER_HOST=$(ifconfig eth1 | grep "inet addr" | awk '{print $2}'| cut -d":" -f2)

export DOCKER_IP=$(echo ${DOCKER_HOST:-tcp://127.0.0.1:2376} | cut -d/ -f3 | cut -d: -f1)

# to be used as registry domain
export FLOATING_IP="${DOCKER_IP}"

# domain we're creating cert for
export DOMAIN="${FLOATING_IP}:5000"

# A blank passphrase
export PASSPHRASE=""

# Set our CSR variables
export SUBJ="
C=US
ST=Connecticut
O=
localityName=New Haven
commonName=$DOMAIN
organizationalUnitName=
emailAddress=
"

mkdir -p "${SSL_DIR}"

openssl req \
  -newkey rsa:4096 -nodes -sha256 \
  -subj "$(echo -n "$SUBJ" | tr "\n" "/")" \
  -keyout ${SSL_DIR}/domain.key \
  -x509 -days 356 \
  -out ${SSL_DIR}/domain.crt

sudo mkdir -p /etc/docker/certs.d/${FLOATING_IP}:5000
sudo cp -frv ${SSL_DIR}/domain.* /etc/docker/certs.d/${FLOATING_IP}:5000/
sudo chmod 400 /etc/docker/certs.d/${FLOATING_IP}:5000/domain.crt

# FIXME: THIS DOESN'T ACCTUALLY APPEND ANYTHING YET
# Add new insecure registry to /var/lib/boot2docker/profile
echo "EXTRA_ARGS=\"\$EXTRA_ARGS --insecure-registry https://${DOMAIN}\"" | sudo tee -a /var/lib/boot2docker/profile
cat /var/lib/boot2docker/profile

sudo cp ${SSL_DIR}/domain.crt /usr/local/share/ca-certificates/
sudo chmod 400 /usr/local/share/ca-certificates/domain.crt
sudo cat /usr/local/share/ca-certificates/domain.crt | grep 'BEGIN.* CERTIFICATE' | wc -l

sudo openssl x509 -noout -fingerprint -in /usr/local/share/ca-certificates/domain.crt

sudo ln -s /usr/local/share/ca-certificates/domain.crt /etc/ssl/certs/domain.pem

cd /etc/ssl/certs && sudo ln -s /etc/ssl/certs/domain.pem `sudo openssl x509 -noout -hash -in /usr/local/share/ca-certificates/domain.crt`.0

echo "Verify it exists. Should look something like this: lrwxrwxrwx    1 root     root            25 Oct  6 02:50 f336d4f6.0 -> /etc/ssl/certs/domain.pem"
ls -lta | head

sudo cp -f /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt.ORIG

echo "BEFORE we append to /etc/ssl/certs/ca-certificates.crt"
sudo cat /etc/ssl/certs/ca-certificates.crt

sudo cat /usr/local/share/ca-certificates/domain.crt | sudo tee -a /etc/ssl/certs/ca-certificates.crt

echo "AFTER we append to /etc/ssl/certs/ca-certificates.crt"
sudo cat /etc/ssl/certs/ca-certificates.crt

cd $HOME

echo "Please reboot docker-machine now!"
