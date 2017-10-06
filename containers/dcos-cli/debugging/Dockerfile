FROM bossjones/dcos-cli-docker:latest

# originally from
# MAINTAINER "Tim <tim.fall@mesosphere.io>"

MAINTAINER Malcolm Jones <bossjones@theblacktonystark.com>

RUN apt-get update && apt-get -y install \
                              linux-tools \
                              traceroute \
                              wget \
                              curl \
                              iputils-arping \
                              iputils-ping \
                              iputils-tracepath \
                              iputils-clockdiff \
                              jq \
                              gdb \
                              sysstat \
                              procps \
                              htop \
                              vim \
                              emacs \
                              git \
                              findutils\
 && apt-get clean

ADD ./toolbox ./toolbox
