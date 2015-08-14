FROM blacklabelops/centos
MAINTAINER Steffen Bleul <blacklabelops@itbleul.de>

# install dev tools
RUN yum install -y \
    tar \
    gzip \
    vi \
    cronie && \
    yum clean all && rm -rf /var/cache/yum/* && \
    mkdir -p /opt/logrotate

COPY imagescripts/docker-entrypoint.sh /opt/logrotate/docker-entrypoint.sh
ENTRYPOINT ["/opt/logrotate/docker-entrypoint.sh"]
CMD ["cron"]
