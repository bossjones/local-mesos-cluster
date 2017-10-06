FROM fedora
RUN dnf install -y perf \
                   traceroute \
                   wget \
                   curl \
                   iputils \
                   jq \
                   gdb \
                   sysstat \
                   procps \
                   htop \
                   vim \
                   emacs \
                   git \
                   findutils \
                   strace \
                   ltrace \
                   trace-cmd \
                   iftop \
                   iotop \
                   dstat \
                   git \
                   maven \
                   tcpdump \
                   mtr \
                   bind-utils \
                   tar \
                   zip \
                   nc \
            && \
            git clone --depth 1 https://github.com/brendangregg/perf-tools /root/perf-tools && \
            git clone --depth 1 https://github.com/feldoh/guano /root/guano && \
            git clone --depth 1 https://github.com/brendangregg/FlameGraph /root/FlameGraph && \
            mvn package -f /root/guano/ && \
            find /root/perf-tools/** -executable -type f -exec cp {} /usr/local/bin/ \; && \
            bash -c 'echo alias guano=\"java -jar /root/guano/target/guano-0.1a.jar\" >> /root/.bashrc' && \
            bash -c 'echo mount -t debugfs nodev /sys/kernel/debug >> /root/.bashrc' && \
            ln -s /media/root/opt/mesosphere/ /opt/mesosphere && \
            dnf clean all && \
            rm -rf /var/cache/dnf

ADD performance-guide.txt /root/
