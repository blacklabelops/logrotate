FROM alpine:3.10
MAINTAINER ThinkReservations <support@thinkreservations.com>

# logrotate version (e.g. 3.9.1-r0)
ARG LOGROTATE_VERSION=latest
# permissions
ARG CONTAINER_UID=1000
ARG CONTAINER_GID=1000

# install dev tools
RUN export CONTAINER_USER=logrotate && \
    export CONTAINER_GROUP=logrotate && \
    addgroup -g $CONTAINER_GID logrotate && \
    adduser -u $CONTAINER_UID -G logrotate -h /usr/bin/logrotate.d -s /bin/bash -S logrotate && \
    apk upgrade --update && \
    apk add --update \
      bash \
      tar \
      gzip \
      wget \
      tini \
      tzdata && \
    if  [ "${LOGROTATE_VERSION}" = "latest" ]; \
      then apk add logrotate ; \
      else apk add "logrotate=${LOGROTATE_VERSION}" ; \
    fi && \
    mkdir -p /usr/bin/logrotate.d && \
    wget -O /tmp/go-cron.tar.gz https://github.com/michaloo/go-cron/releases/download/v0.0.2/go-cron.tar.gz && \
    echo "f84ef029ec5dd7f5bcb32cd729b2a5bb  /tmp/go-cron.tar.gz" > /tmp/checksum && \
    md5sum -c /tmp/checksum && \
    tar xvf /tmp/go-cron.tar.gz -C /usr/bin && \
    apk del \
      wget && \
    # https://github.com/docker-library/docker/pull/84/files
    if [ ! -e /etc/nsswitch.conf ]; \
        then echo 'hosts: files dns' > /etc/nsswitch.conf; \
    fi && \
    rm -rf /var/cache/apk/* /tmp/* /var/log/*

# environment variable for this container
ENV LOGROTATE_OLDDIR= \
    LOGROTATE_COMPRESSION= \
    LOGROTATE_INTERVAL= \
    LOGROTATE_COPIES= \
    LOGROTATE_SIZE= \
    LOGS_DIRECTORIES= \
    LOG_FILE_ENDINGS= \
    LOGROTATE_LOGFILE= \
    LOGROTATE_CRONSCHEDULE= \
    LOGROTATE_PARAMETERS= \
    LOGROTATE_STATUSFILE= \
    LOG_FILE=

COPY src/docker-entrypoint.sh /usr/bin/logrotate.d/docker-entrypoint.sh
COPY src/update-logrotate.sh /usr/bin/logrotate.d/update-logrotate.sh
COPY src/logrotate.sh /usr/bin/logrotate.d/logrotate.sh
COPY src/logrotateConf.sh /usr/bin/logrotate.d/logrotateConf.sh
COPY src/logrotateCreateConf.sh /usr/bin/logrotate.d/logrotateCreateConf.sh

ENTRYPOINT ["/sbin/tini","--","/usr/bin/logrotate.d/docker-entrypoint.sh"]
VOLUME ["/logrotate-status"]
CMD ["cron"]
