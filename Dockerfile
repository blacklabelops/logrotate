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

COPY imagescripts/docker-entrypoint.sh /opt/logrotate/docker-entrypoint.sh
ENTRYPOINT ["/opt/logrotate/docker-entrypoint.sh"]
CMD ["cron"]
