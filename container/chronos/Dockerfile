# Borrowed from yelp
# Copyright 2015-2016 Yelp Inc.

FROM ubuntu:xenial

RUN apt-get update > /dev/null && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    apt-transport-https \
    software-properties-common > /dev/null && \
    echo "deb https://dl.bintray.com/yelp/paasta xenial main" > /etc/apt/sources.list.d/paasta.list && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv 8756C4F765C9AC3CB6B85D62379CE192D401AB61 && \
    echo "deb http://repos.mesosphere.com/ubuntu xenial main" > /etc/apt/sources.list.d/mesosphere.list && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv 81026D0004C44CF7EF55ADF8DF7D54CBE56151BF && \
    apt-get update > /dev/null && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install \
    libsasl2-modules mesos=1.3.0-2.0.3 > /dev/null && \
    apt-get clean

RUN apt-get update > /dev/null && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    lsb-release \
    chronos=2.5.0-yelp32-1.ubuntu1604 \
    rsyslog \
    && \
    apt-get clean

# Chronos will look in here for zk config, so we blow away the bogus defaults
RUN rm -rf /etc/mesos/

RUN echo 8081 > /etc/chronos/conf/http_port
RUN echo 'zk://zookeeper:2181/mesos-testcluster' > /etc/chronos/conf/master
RUN echo 'zookeeper:2181' > /etc/chronos/conf/zk_hosts
RUN echo '/chronos' > /etc/chronos/conf/zk_path
RUN echo -n 'chronos' > /etc/chronos/conf/mesos_authentication_principal
RUN echo -n 'secret3' > /etc/chronos_framework_secret
RUN echo -n '/etc/chronos_framework_secret' > /etc/chronos/conf/mesos_authentication_secret_file

CMD rsyslogd ; sleep 1; (/usr/bin/chronos &) ; tail -f /var/log/syslog

EXPOSE 8081
