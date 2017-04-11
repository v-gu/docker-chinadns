#
# Dockerfile for chinadns
#

FROM alpine
MAINTAINER Vincent.Gu <g@v-io.co>

ENV UDP_PORT        53
ENV TCP_PORT        53

ENV APP_DIR         /srv/chinadns
ENV CDNS_VER        1.3.2
ENV CDNS_URL        https://github.com/shadowsocks/ChinaDNS/releases/download/${CDNS_VER}/chinadns-${CDNS_VER}.tar.gz
ENV CDNS_DIR        $APP_DIR/chinadns-$CDNS_VER
ENV CHNROUTE_FILE   $APP_DIR/chnroute.txt

EXPOSE $UDP_PORT/udp
EXPOSE $TCP_PORT/tcp

# build software stack
ENV BUILD_DEP musl-dev gcc gawk make libtool curl
RUN set -ex \
    && echo '114.114.114.114' > /etc/resolv.conf \
    && echo '151.101.128.249 dl-cdn.alpinelinux.org' >> /etc/hosts \
    && echo '192.30.255.112 github.com' >> /etc/hosts \
    && echo '52.216.224.56 github-cloud.s3.amazonaws.com' >> /etc/hosts \
    && echo '202.12.29.205 ftp.apnic.net' >> /etc/hosts \
    && apk --update --no-cache add $BUILD_DEP $DEP \
    && mkdir -p $APP_DIR \
    && curl -sSL "$CDNS_URL" | tar xz -C $APP_DIR \
    && echo '172.18.18.12/32' > $APP_DIR/chnroute.txt \
    && curl 'http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest' \
        | grep ipv4 \
        | grep CN \
        | awk -F\| '{printf("%s/%d\n", $4, 32-log($5)/log(2))}' >> $APP_DIR/chnroute.txt \
    && cd $CDNS_DIR \
    && ./configure \
    && make install \
    && cd $APP_DIR \
    && rm -rf $CDNS_DIR \
    && apk del --purge $BUILD_DEP \
    && rm -rf /var/cache/apk/*

ENTRYPOINT ["/usr/local/bin/chinadns", "-p", "53", "-m", "-y", "0.3", "-d", \
            "-c", "/srv/chinadns/chnroute.txt", \
            "-s", "172.18.18.12,172.18.18.13"]
