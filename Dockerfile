FROM alpine
LABEL MAINTAINER="Greg White <grewhit23@gmail.com>"

# logrotate version (e.g. 3.9.1-r0)
ARG LOGROTATE_VERSION=latest
# permissions
ARG CONTAINER_UID=1000
ARG CONTAINER_GID=1000
ENV GOPATH /usr/bin

# install dev tools
RUN export CONTAINER_USER=logrotate && \
    export CONTAINER_GROUP=logrotate && \
    addgroup -g $CONTAINER_GID logrotate && \
    adduser -u $CONTAINER_UID -G logrotate -h /usr/bin/logrotate.d -s /bin/bash -S logrotate && \
    apk add --update && \
    apk add --virtual build-dependencies \
      go gcc g++ wget git tar gzip && \
    apk add \
      bash \
      tini \
      tzdata && \
    if  [ "${LOGROTATE_VERSION}" = "latest" ]; \
      then apk add logrotate ; \
      else apk add "logrotate=${LOGROTATE_VERSION}" ; \
    fi && \
    mkdir -p /usr/bin/logrotate.d && \
    cd ${GOPATH} && \
    mkdir -p src/github.com/odise/ && \
    cd src/github.com/odise && \
    git clone https://github.com/odise/go-cron.git && \
    cd go-cron && \
    go get -d && \
    go build -o /usr/bin/go-cron -ldflags "-X main.build=`git rev-parse --short HEAD`" bin/go-cron.go && \
    apk del build-dependencies && \
    rm -rf /var/cache/apk/* && \
    rm -rf ${GOPATH}/src && \
    rm -rf /tmp/*

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

COPY *.sh /usr/bin/logrotate.d/

ENTRYPOINT ["/sbin/tini","--","/usr/bin/logrotate.d/docker-entrypoint.sh"]
VOLUME ["/logrotate-status"]
CMD ["cron"]
