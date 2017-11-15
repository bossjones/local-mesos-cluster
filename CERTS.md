# Exact commands required on fedora ( BOSSJONES VERIFIED )

```
sudo cp /etc/pki/tls/openssl.cnf /tmp/openssl.cnf
export HOST_IP=$(curl ipv4.icanhazip.com 2>/dev/null)
echo $HOST_IP

sudo sed -i "/\[ v3_ca \]/a subjectAltName = IP:${HOST_IP}" /tmp/openssl.cnf
sudo cat /tmp/openssl.cnf | grep ${HOST_IP}
sudo chown pi:pi /tmp/openssl.cnf

cd /home/pi/dev/local-mesos-cluster
openssl req -config /tmp/openssl.cnf \
-newkey rsa:4096 -nodes -sha256 \
-keyout certs/domain.key \
-x509 -days 3650 \
-subj "/C=/ST=/L=/O=/CN=${HOST_IP}:5000" \
-out certs/domain.crt

sudo cp certs/domain.crt /etc/pki/ca-trust/source/anchors/${HOST_IP}:5000.crt
sudo chown root:root /etc/pki/ca-trust/source/anchors/${HOST_IP}:5000.crt
sudo chmod 400 /etc/pki/ca-trust/source/anchors/${HOST_IP}:5000.crt
sudo ls -lta /etc/pki/ca-trust/source/anchors/
sudo update-ca-trust
sudo service docker restart

# test it out
docker pull kennethreitz/httpbin:latest
docker tag kennethreitz/httpbin:latest ${HOST_IP}:5000/kennethreitz/httpbin:latest
docker push ${HOST_IP}:5000/kennethreitz/httpbin:latest
```

**Borrowed from: https://github.com/bsstokes/xip.io-cert/blob/master/README.md**


# Self-Signed SSL Certificate for xip.io

If you use [xip.io](http://xip.io/) with your development environment, here's an SSL certificate that might come in handy.

**This certificate is for development only.** You're browser will probably complain that it's self-signed and hasn't been verified.

- `xip.io.key` -- *Private* key
- `xip.io.csr` -- Certificate signing request
- `xip.io.crt` -- Self-signed certificate

## Here's How I Created the Files

### Private Key

    openssl genrsa -out xip.io.key 1024

### Certificate Signing Request (CSR)

    openssl req -new -key xip.io.key -out xip.io.csr

*Common Name* is `*.xip.io`, and the rest of the fields are blank.

### Self-Signed Certificate

    openssl x509 -req -days 365 -in xip.io.csr -signkey xip.io.key -out xip.io.crt

## Example nginx.conf Snippet

    server {
      listen       443;
      server_name  *.xip.io;

      ssl on;
      ssl_certificate     /path/to/certs/xip.io-cert/xip.io.crt;
      ssl_certificate_key /path/to/certs/xip.io-cert/xip.io.key;

      # The rest of the config...
    }


------------------------------------

# Certs option

**source: https://github.com/jssept04/jitendra-openshift/blob/83a0e4c021bbdf08c370665a7db87d5654f5c85d/ansible-docker-registry-master/tasks/certificate.yml**

```

---

  - local_action: file path={{inventory_dir}}/registry state=directory

  - local_action: stat path={{inventory_dir}}/registry/domain.crt
    register: local_certificate

  - name: copy openssl configuration for RedHat
    shell: cp /etc/pki/tls/openssl.cnf /tmp/openssl.cnf
    sudo: yes
    when: not local_certificate.stat.exists and ansible_os_family == "RedHat"

  - name: copy openssl configuration for Debian
    shell: cp /usr/local/ssl/openssl.cnf /tmp/openssl.cnf
    sudo: yes
    when: not local_certificate.stat.exists and ansible_os_family == "Debian"

  - name: update openssl configuration
    shell: sed -i "/\[ v3_ca \]/a subjectAltName = IP:{{docker.registry.ip}}" /tmp/openssl.cnf
    sudo: yes
    when: not local_certificate.stat.exists

  - name: create server key and certificate
    shell: openssl req -config /tmp/openssl.cnf -newkey rsa:2048 -nodes -x509 -subj "/C=/ST=/L=/O=/CN={{docker.registry.host}}" -days 365 -keyout /tmp/domain.key -out /tmp/domain.crt
    sudo: yes
    when: not local_certificate.stat.exists

  - name: download server key and certificate
    fetch: src=/tmp/{{item}} dest={{inventory_dir}}/registry/ flat=yes
    with_items:
      - domain.crt
      - domain.key
    when: not local_certificate.stat.exists

  - copy: src={{inventory_dir}}/registry/domain.{{item}} dest=/etc/nginx/certs/{{docker.registry.host}}.{{item}}
    sudo: yes
    with_items:
      - key
      - crt

  - copy: src={{inventory_dir}}/registry/domain.crt dest=/usr/local/share/ca-certificates/{{docker.registry.host}}.crt
    sudo: yes
    when: ansible_os_family == "Debian"

  - shell: update-ca-certificates
    sudo: yes
    when: ansible_os_family == "Debian"

  - copy: src={{inventory_dir}}/registry/domain.crt dest=/etc/pki/ca-trust/source/anchors/{{docker.registry.host}}.crt
    sudo: yes
    when: ansible_os_family == "RedHat"

  - shell: update-ca-trust
    sudo: yes
    when: ansible_os_family == "RedHat"

  - file: path=/etc/docker/certs.d/{{docker.registry.host}} state=directory
    sudo: yes

  - copy: src={{inventory_dir}}/registry/domain.crt dest=/etc/docker/certs.d/{{docker.registry.host}}/ca.crt
    sudo: yes
    notify: restart docker
```
