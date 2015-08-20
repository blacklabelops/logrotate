FROM blacklabelops/centos
MAINTAINER Steffen Bleul <blacklabelops@itbleul.de>

# Propert permissions
ENV CONTAINER_USER logrotate
ENV CONTAINER_UID 1000
ENV CONTAINER_GROUP logrotate
ENV CONTAINER_GID 1000

RUN /usr/sbin/groupadd --gid $CONTAINER_GID $CONTAINER_GROUP && \
    /usr/sbin/useradd --uid $CONTAINER_UID --gid $CONTAINER_GID --create-home --home-dir /usr/bin/logrotate.d --shell /bin/bash $CONTAINER_GROUP

# install dev tools
RUN yum install -y \
    tar \
    gzip \
    vi \
    cronie && \
    yum clean all && rm -rf /var/cache/yum/* && \
    mkdir -p /usr/bin/logrotate.d

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
ENV LOG_FILE=

COPY imagescripts/docker-entrypoint.sh /usr/bin/logrotate.d/docker-entrypoint.sh
ENTRYPOINT ["/usr/bin/logrotate.d/docker-entrypoint.sh"]
CMD ["cron"]
