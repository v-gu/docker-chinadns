#!/usr/bin/env sh

exec /usr/local/bin/chinadns -p 53 -m -y 0.3 -d \
            -c /srv/chinadns/chnroute.txt \
            -s "${CHINA_DNS},${OFFSHORE_DNS}"
