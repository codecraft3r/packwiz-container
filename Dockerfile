FROM alpine:3.22.1

ENV PACKWIZ_URL=""
ENV MB_RAM=4096

# Install dependencies
RUN apk add --no-cache \
    openjdk21-jre-headless \
    dos2unix \
    curl \
    wget \
    jq \
    tar \
    go \
    bash

COPY setup.sh /setup.sh
COPY entrypoint.sh /entrypoint.sh

# Ensure line endings and set permissions, then remove dos2unix
RUN dos2unix /setup.sh /entrypoint.sh && \
    chmod +x /setup.sh /entrypoint.sh && \
    apk del dos2unix

COPY mc-eula.txt /mnt/server/eula.txt

VOLUME ["/mnt/server"]

EXPOSE 25565

ENTRYPOINT ["/entrypoint.sh"]