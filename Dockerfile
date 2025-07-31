FROM alpine:3.22.1

# Environment variables
ENV PACKWIZ_URL=""
ENV WHITELIST_JSON=""
ENV MB_RAM=4096

# Install runtime dependencies & tools
RUN apk add --no-cache \
    openjdk21-jre-headless \
    curl \
    jq \
    nano \
    tar

# Add setup tools
RUN apk add --no-cache \
    runuser \
    dos2unix \
    go

# Perform initial setup
COPY mc-setup.sh /mc-setup.sh
COPY entrypoint.sh /entrypoint.sh
COPY exec-setup.sh /exec-setup.sh
COPY mc-eula.txt /mnt/server/eula.txt

RUN dos2unix /mc-setup.sh /entrypoint.sh /exec-setup.sh && \
    chmod +x /mc-setup.sh /entrypoint.sh /exec-setup.sh

RUN runuser -l root -c "sh /exec-setup.sh" && \
    rm -rf /exec-setup.sh

# Remove setup tools
RUN apk del dos2unix runuser go

# Container configuration
USER root
VOLUME ["/mnt/server"]
EXPOSE 25565

ENTRYPOINT ["sh", "/entrypoint.sh"]
