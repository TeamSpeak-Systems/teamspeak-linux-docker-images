FROM alpine:3.6 AS builder

ARG TEAMSPEAK_VERSION=3.1.0.0
ARG TEAMSPEAK_CHECKSUM=TODO
ARG TEAMSPEAK_URL=http://dl.4players.de/ts/releases/${TEAMSPEAK_VERSION}/teamspeak3-server_linux_alpine-${TEAMSPEAK_VERSION}.tar.bz2

RUN apk add --update tar ca-certificates

# download and unpack ts3server
RUN wget "${TEAMSPEAK_URL}" -O server.tar.bz2
RUN echo "${TEAMSPEAK_CHECKSUM}  server.tar.bz2" | sha256sum -c -
RUN mkdir -p /opt/ts3server
RUN tar -xf server.tar.bz2 --strip-components=1 -C /opt/ts3server

COPY entrypoint.sh /opt/ts3server

FROM alpine:latest

COPY --from=builder /opt/ts3server /opt/ts3server

# setup directory where user data is stored
VOLUME /var/ts3server/
WORKDIR /var/ts3server/

# install depencies, and add ts3server user/group
RUN apk add --no-cache libstdc++ ca-certificates su-exec \
 && mv /opt/ts3server/*.so /opt/ts3server/redist/* /usr/local/lib && ldconfig /usr/local/lib \
 && addgroup ts3server \
 && adduser -Hh /var/ts3server -G ts3server -s /sbin/nologin -D ts3server \
 && chown -R ts3server:ts3server /opt/ts3server /var/ts3server

#  9987 default voice
# 10011 server query
# 30033 file transport
EXPOSE 9987/udp 10011 30033 

ENV PATH "${PATH}:/opt/ts3server"

ENTRYPOINT [ "/opt/ts3server/entrypoint.sh" ]
CMD [ "ts3server" ]
