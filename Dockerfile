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
ENV CHINA_DNS       127.0.0.1:5353
ENV OFFSHORE_DNS    127.0.1.1:5354

EXPOSE $UDP_PORT/udp
EXPOSE $TCP_PORT/tcp

WORKDIR $APP_DIR

# build software stack
ENV BUILD_DEP musl-dev gcc gawk make libtool curl
RUN set -ex \
    && apk --update --no-cache add $BUILD_DEP $DEP \
    && curl -sSL "$CDNS_URL" | tar xz -C $APP_DIR \
    && echo '10.0.0.0/8' >> $APP_DIR/chnroute.txt \
    && echo '172.16.0.0/12' >> $APP_DIR/chnroute.txt \
    && echo '192.168.0.0/16' >> $APP_DIR/chnroute.txt \
    && echo '127.0.0.0/24' >> $APP_DIR/chnroute.txt \
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

ADD entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
