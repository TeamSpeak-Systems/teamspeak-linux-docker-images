FROM alpine:3.7

RUN apk add --no-cache ca-certificates libstdc++ su-exec
RUN set -eux; \
 addgroup -g 9987 ts3server; \
 adduser -u 9987 -Hh /var/ts3server -G ts3server -s /sbin/nologin -D ts3server; \
 mkdir -p /var/ts3server /var/run/ts3server; \
 chown ts3server:ts3server /var/ts3server /var/run/ts3server; \
 chmod 777 /var/ts3server /var/run/ts3server

ENV PATH "${PATH}:/opt/ts3server"

ARG TEAMSPEAK_CHECKSUM=cca4071addd9e68b53564c5c0ed361a3f798693350a64de122feadf1c7b3e8bb
ARG TEAMSPEAK_URL=https://files.teamspeak-services.com/releases/server/3.9.0/teamspeak3-server_linux_alpine-3.9.0.tar.bz2

RUN set -eux; \
 apk add --no-cache --virtual .fetch-deps tar; \
 wget "${TEAMSPEAK_URL}" -O server.tar.bz2; \
 echo "${TEAMSPEAK_CHECKSUM} *server.tar.bz2" | sha256sum -c -; \
 mkdir -p /opt/ts3server; \
 tar -xf server.tar.bz2 --strip-components=1 -C /opt/ts3server; \
 rm server.tar.bz2; \
 apk del .fetch-deps; \
 mv /opt/ts3server/*.so /opt/ts3server/redist/* /usr/local/lib; \
 ldconfig /usr/local/lib; \
 chown -R ts3server:ts3server /opt/ts3server

# setup directory where user data is stored
VOLUME /var/ts3server/
WORKDIR /var/ts3server/

#  9987 default voice
# 10011 server query
# 30033 file transport
EXPOSE 9987/udp 10011 30033 

COPY entrypoint.sh /opt/ts3server
ENTRYPOINT [ "entrypoint.sh" ]
CMD [ "ts3server" ]
