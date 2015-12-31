FROM blacklabelops/centos:7.2.1511
MAINTAINER Steffen Bleul <sbl@blacklabelops.com>

# Propert permissions
ENV CONTAINER_USER logrotate
ENV CONTAINER_UID 1000
ENV CONTAINER_GROUP logrotate
ENV CONTAINER_GID 1000

RUN /usr/sbin/groupadd --gid $CONTAINER_GID $CONTAINER_GROUP && \
    /usr/sbin/useradd --uid $CONTAINER_UID --gid $CONTAINER_GID --create-home --home-dir /usr/bin/logrotate.d --shell /bin/bash $CONTAINER_GROUP

ENV VOLUME_DIRECTORY=/logrotate-status

# install dev tools
RUN yum install -y \
    tar \
    gzip \
    wget \
    vi \
    logrotate-3.8.6 && \
    yum clean all && rm -rf /var/cache/yum/* && \
    mkdir -p /usr/bin/logrotate.d && \
    wget --no-check-certificate -O /tmp/go-cron.tar.gz https://github.com/michaloo/go-cron/releases/download/v0.0.2/go-cron.tar.gz && \
    tar xvf /tmp/go-cron.tar.gz -C /usr/bin && \
    rm -rf /tmp/*

# environment variable for this container
ENV LOGROTATE_OLDDIR=
ENV LOGROTATE_COMPRESSION=
ENV LOGROTATE_INTERVAL=
ENV LOGROTATE_COPIES=
ENV LOGROTATE_SIZE=
ENV LOGS_DIRECTORIES=
ENV LOG_FILE_ENDINGS=
ENV LOGROTATE_LOGFILE=
ENV LOGROTATE_CRONSCHEDULE=
ENV LOGROTATE_PARAMETERS=
ENV LOGROTATE_STATUSFILE=
ENV LOG_FILE=

COPY imagescripts/docker-entrypoint.sh /usr/bin/logrotate.d/docker-entrypoint.sh
ENTRYPOINT ["/usr/bin/logrotate.d/docker-entrypoint.sh"]
VOLUME ["${VOLUME_DIRECTORY}"]
CMD ["cron"]
