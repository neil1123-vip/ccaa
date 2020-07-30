FROM alpine:latest
MAINTAINER neil1123 "neil1123@vip.qq.com"
CMD ["/bin/sh"]
WORKDIR /root
RUN apk add --no-cache bash curl wget zip tar bzip2 unzip ca-certificates && \
    wget https://github.com/neil1123-vip/ccaa/raw/master/docker-ccaa.sh && \
    sh docker-ccaa.sh install && \
    rm -rf /var/cache/apk/*
VOLUME [/data/ccaaDown]
EXPOSE 51413/tcp 6080/tcp 6081/tcp 6800/tcp
