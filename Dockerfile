FROM ghcr.io/graalvm/jdk-community:21.0.2-ol9-20240116

# Environment variables
ENV PACKWIZ_URL=""
ENV GH_USER=""
ENV GH_REPO=""
ENV PACK_VERSION=""

ENV MB_RAM=4096

# Install runtime dependencies & tools
RUN microdnf install -y \
    curl \
    jq \
    nano \
    tar \
    gzip \
    findutils

# Add setup tools
RUN microdnf install -y \
    util-linux \
    dos2unix \
    golang 

# Perform initial setup
COPY mc-setup.sh /mc-setup.sh
COPY entrypoint.sh /entrypoint.sh
COPY exec-setup.sh /exec-setup.sh
COPY fetch-latest-release.sh /fetch-latest-release.sh
COPY mc-eula.txt /mnt/server/eula.txt

RUN dos2unix /mc-setup.sh /entrypoint.sh /exec-setup.sh /fetch-latest-release.sh && \
    chmod +x /mc-setup.sh /entrypoint.sh /exec-setup.sh /fetch-latest-release.sh

RUN runuser -l root -c "sh /exec-setup.sh" && \
    rm -rf /exec-setup.sh

# Remove setup tools
# RUN microdnf remove -y dos2unix golang go - disable for now

# Container configuration
USER root
VOLUME ["/mnt/server/world"]
EXPOSE 25565

ENTRYPOINT ["sh", "/entrypoint.sh"]
