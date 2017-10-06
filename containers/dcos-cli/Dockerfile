FROM python:3.5-slim

# originally from
# MAINTAINER "Tim <tim.fall@mesosphere.io>"

MAINTAINER Malcolm Jones <bossjones@theblacktonystark.com>

RUN apt-get update && \
    apt-get install -y vim wget curl python-pip openjdk-7-jre-headless && \
    pip install virtualenv

WORKDIR /dcos

ADD https://downloads.mesosphere.io/dcos-cli/install.sh install.sh
ADD startup.sh /usr/local/bin/startup.sh
RUN chmod +x /usr/local/bin/startup.sh

ENTRYPOINT ["/usr/local/bin/startup.sh"]
