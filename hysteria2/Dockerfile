FROM alpine:latest

RUN apk add --no-cache wget ca-certificates bash

WORKDIR /opt/hysteria

# Download Hysteria 2
RUN wget -O hysteria https://github.com/apernet/hysteria/releases/latest/download/hysteria-linux-amd64 && \
    chmod +x hysteria && \
    mv hysteria /usr/local/bin/

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 443/udp
EXPOSE 8443/udp

ENTRYPOINT ["/entrypoint.sh"]
