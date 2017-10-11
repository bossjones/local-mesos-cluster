# fix this

```
 |2.2.3|  using virtualenv: local-mesos-cluster2  Malcolms-MBP-3 in ~/dev/bossjones/local-mesos-cluster
± |feature-init U:1 ✗| → docker push 192.168.99.101:5000/paddycarey/httpbin:latest
The push refers to a repository [192.168.99.101:5000/paddycarey/httpbin]
Get https://192.168.99.101:5000/v2/: x509: cannot validate certificate for 192.168.99.101 because it doesn't contain any IP SANs
```


# AUTOMATE THIS PLEASE ( lets use fabric for it, or ansible, your pick )

```
# Self-Signed Registry With Access Restriction ( run this on docker-machine, boot2docker )
docker-machine ssh dev

# -----------------------------------------------------------
# create certs
# NOTE: For common name use result of this `docker-machine ip dev`
# -----------------------------------------------------------
mkdir certs && \
openssl req \
  -newkey rsa:4096 -nodes -sha256 \
  -keyout certs/domain.key \
  -x509 -days 3650 \
  -out certs/domain.crt

# -----------------------------------------------------------
# Install self signed cert as a trusted ca
# -----------------------------------------------------------
# source: https://github.com/boot2docker/boot2docker/issues/347#issuecomment-187552378
# This fixes issue: https://github.com/docker/distribution/issues/948
# Append subjectAltName after v3_ca
sed  -i '/\[ v3_ca \]/a subjectAltName = IP:192.168.99.101' /etc/ssl/openssl.cnf

# verify it was appended correctly
grep "subjectAltName = IP" /etc/ssl/openssl.cnf

# regenerate cert again (use the generate-ssl-registry.sh script)

# do all of this
sudo cp certs/domain.crt /usr/local/share/ca-certificates/

sudo cp domain.crt /usr/local/share/ca-certificates/

cat /usr/local/share/ca-certificates/domain.crt | grep 'BEGIN.* CERTIFICATE' | wc -l
openssl x509 -noout -fingerprint -in /usr/local/share/ca-certificates/domain.crt
sudo ln -s /usr/local/share/ca-certificates/domain.crt /etc/ssl/certs/domain.pem
cd /etc/ssl/certs && sudo ln -s /etc/ssl/certs/domain.pem `openssl x509 -noout -hash -in /usr/local/share/ca-certificates/domain.crt`.0
ls /etc/ssl/certs/ca-certificates.crt

sudo su -
cat /usr/local/share/ca-certificates/domain.crt >> /etc/ssl/certs/ca-certificates.crt
exit

# -----------------------------------------------------------
# create the /etc/docker/certs.d/<ip>:<port>/ folder
# -----------------------------------------------------------
sudo mkdir -p /etc/docker/certs.d/172.16.223.128:5000
sudo mv /tmp/ca.crt /etc/docker/certs.d/172.16.223.128:5000/ca.crt
sudo chmod 400 /etc/docker/certs.d/172.16.223.128:5000/ca.crt

# -----------------------------------------------------------
# modify /var/lib/boot2docker/profile and added EXTRA_ARGS w/ insecure-registry
# -----------------------------------------------------------
echo 'EXTRA_ARGS="$EXTRA_ARGS --insecure-registry 172.16.223.128:5000"' >>  /var/lib/boot2docker/profile
```


# fab

```
def run_terminate():
    """Stop mesos-slave on all broken hosts in batches of 3 with a time out. Then print terminate ec2 instance command."""
    # Pull back all long staging mesos tasks
    broken_hosts = run_query_for_broken_mesos_hosts()

    # We'll manually set our host list here after filtering for private ips
    host_ips = []

    for i in broken_hosts:
        host_ips.append(i[0])

    print('******************************************host_ips******************************************')
    print(host_ips)

    # Define list of hosts to run fabric commands against
    env.hosts = host_ips

    # Tell fabric to use public_ip of jumpbox
    env.gateway = set_jumpbox_fabric_gateway()

    # FIXME: We need to REALLY test this before enabling it!
    # Run fabric task
    # # Run fabric task
    with settings(
        parallel=True,
        pool_size=3,
        hosts=env.hosts,
        gateway=env.gateway,
        remote_interrupt=env.remote_interrupt,
        use_ssh_config=env.use_ssh_config,
        disable_known_hosts=env.disable_known_hosts,
        forward_agent=env.forward_agent,
        keepalive=env.keepalive,
        key_filename=env.key_filename,
        user=env.user,
        abort_on_prompts=env.abort_on_prompts,
        sudo_prefix=env.sudo_prefix,
    ):
        tasks.execute(schedule_maintenance_and_remove_agent)

    print("Okay! Everything should be stopped! All that's left to do is kill all of the bad hosts!")
    run_print_terminate()
```

# python bash replacement

https://stackoverflow.com/questions/209470/can-i-use-python-as-a-bash-replacement


# missing SAN, lets try this?

```
# FIXME: Orig
# openssl req \
#   -newkey rsa:4096 -nodes -sha256 \
#   -keyout certs/domain.key \
#   -x509 -days 356 \
#   -out certs/domain.crt \
#   -config host.cfg

export IPADDR=$(docker-machine ip dev)

\cat > host.cfg << EOF
[req]
distinguished_name = req_distinguished_name
x509_extensions = v3_req
prompt = no

[req_distinguished_name]
C = US
ST = NY
L = New York
O = Behance
OU = DOCKER
CN = ${IPADDR}

[v3_req]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${IPADDR}
DNS.2 = 127.0.0.1
IP.1  = ${IPADDR}
IP.2  = 127.0.0.1
EOF

\cat > ca.conf << EOF
[req]
distinguished_name = req_distinguished_name
req_extensions  = v3_req
x509_extensions = v3_ca
prompt = no
[req_distinguished_name]
C = CA
ST = Alberta
L = Edmonton
O = Example.com
OU = CA
CN = ca.example.com
[v3_req]
keyUsage = keyEncipherment, dataEncipherment, keyCertSign
extendedKeyUsage = serverAuth
subjectAltName = @alt_names
[ v3_ca ]
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid:always,issuer
basicConstraints = CA:true
[alt_names]
DNS.1 = ca.example.com
EOF

\cat > server.conf  << EOF
[req]
distinguished_name = req_distinguished_name
x509_extensions = v3_req
prompt = no
[req_distinguished_name]
C = CA
ST = Alberta
L = Edmonton
O = Example.com
OU = Docker
CN = registry.example.com
[v3_req]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names
basicConstraints = CA:FALSE

[alt_names]
#DNS.1 = registry.example.com
IP.1 = <ip of registry server>
EOF

openssl genrsa -out ca-privkey.pem 2048
openssl req -config ./ca.conf -new -x509 -key ca-privkey.pem \
     -out cacert.pem -days 365
openssl req -config ./server.conf -newkey rsa:2048 -days 365 \
     -nodes -keyout server-key.pem -out server-req.pem
openssl rsa -in server-key.pem -out server-key.pem
openssl x509 -req -in server-req.pem -days 365 \
      -CA cacert.pem -CAkey ca-privkey.pem \
      -set_serial 01 -out server-cert.pem  \
      -extensions v3_req \
      -extfile server.conf

echo "INFO: print cacert.pem..."
openssl x509 -text -in cacert.pem -noout
echo "INFO: print server-req.pem..."
openssl req -text -in server-req.pem -noout
echo "INFO: print server-cert.pem..."
openssl x509 -text -in server-cert.pem -noout
openssl verify -verbose -CAfile ./cacert.pem server-cert.pem

echo "INFO: updating local CA..."

# Have to use .crt file name for update command to work
# sudo cp cacert.pem /usr/local/share/ca-certificates/cacert.crt
```


# Cert fix! (  Get 192.168.1.102:5000/v1/_ping: x509: cannot validate certificate for 192.168.1.102 because it doesn't contain any IP SANs )

*source: https://github.com/docker/distribution/issues/948*
*source: http://serverfault.com/questions/611120/failed-tls-handshake-does-not-contain-any-ip-sans*

```
Thank you for this direction to the correct information.

I had reviewed this page several times with many many other web posts about TLS and docker registry error messages. I did not understand that this logstash solution and docker registry:2 solution with TLS was the same incident, thank you.

I am running a proof of concept with docker without outside help of a security team. This is being setup on a group of four servers that are isolated without DNS to determine what business process changes may be needed for a move to a secure docker.

Stopped and removed the running docker registry:2

Edited the file /etc/ssl/openssl.cnf on the registry:2 host and added
subjectAltName = IP:192.168.2.102 into the [v3_ca] section. Like the following:

…
[ v3_ca ]
subjectAltName = IP:192.168.1.102
...

Recreated the certificate using the same steps and information as defined above

Copied the new certificate using the same steps as defined above on all four hosts

Started registry:2 image using the same steps as defined above

Tested docker push to registry:2 from two hosts and it works.

/mnt-three/TLS-cert$ docker push 192.168.1.102:5000/python
The push refers to a repository [192.168.1.102:5000/python](len: 1)
e1857ee1f3b5: Image successfully pushed
...
902b87aaaec9: Image successfully pushed
2.7: digest: sha256:6da1183aeae37865eadc65cf0d93d68d1d766104bc8c8f32bf772eb87b5a87e0 size: 25093

Hopefully this information will be helpful to others and save them many web search hours.
```

# finish adding dcos-cli

*source: https://stackoverflow.com/questions/39970133/does-dcos-cli-work-with-plain-mesos*

eg. `dcos config set core.mesos_master_url 52.34.160.132:5050`

eg. `dcos config set core.mesos_master_url $(docker-machine ip local-mesos-cluster):5050`


# Pass more mesos options? ( example )

```
ExecStart=/usr/bin/bash -c "source /etc/profile.d/etcdctl.sh && \
  sudo -E docker run \
    --name=agent-mesos \
    --net=host \
    --pid=host \
    --privileged \
    -p 5051:5051 \
    -v /home/core/.dockercfg:/root/.dockercfg:ro \
    -v /sys:/sys \
    -v /usr/bin/docker:/usr/bin/docker:ro \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v /lib64/libdevmapper.so:/lib/libdevmapper.so.1.02:ro \
    -v /lib64/libsystemd.so:/lib/libsystemd.so.0:ro \
    -v /lib64/libgcrypt.so:/lib/libgcrypt.so.20:ro \
    -v /lib64/libgpg-error.so.0:/lib/x86_64-linux-gnu/libgpg-error.so.0:ro \
    -v /lib64/libseccomp.so.2:/lib/x86_64-linux-gnu/libseccomp.so.2:ro \
    -v /var/lib/mesos/slave:/var/lib/mesos/slave \
    -v /opt/mesos/credentials:/opt/mesos/credentials:ro \
    $($IMAGE) \
    --ip=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4) \
    --attributes=zone:$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)\;os:coreos\;worker_group:$WORKER_GROUP \
    --containerizers=docker,mesos \
    --executor_registration_timeout=10mins \
    --hostname=$(curl -s http://169.254.169.254/latest/meta-data/local-hostname) \
    --log_dir=/var/log/mesos \
    --credential=/opt/mesos/credentials \
    --master=zk://$($ZK_USERNAME):$($ZK_PASSWORD)@$($ZK_ENDPOINT)/mesos \
    --work_dir=/var/lib/mesos/slave \
    --cgroups_enable_cfs"
```

# Pyspark Notebook: https://github.com/jupyter/docker-stacks/tree/master/pyspark-notebook
