FROM alpine:3.19
MAINTAINER Albert Zakharov golovgka@gmail.com

RUN apk add --update openssh-client && \
    apk add --no-cache --upgrade bash && \
    rm -rf /var/cache/apk/*
RUN mkdir -p /ssh-keys

COPY . .

CMD sh -c '/ssh-tunnel-connector.sh && tail -f /dev/null'
