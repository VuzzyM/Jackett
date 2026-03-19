FROM alpine:latest

LABEL maintainer="Vuzzy"

ARG uid=1000
ARG gid=1000

ENV XDG_CONFIG_HOME=/config

RUN set -eux; \
    apk add --no-cache \
        ca-certificates \
        curl \
        icu-libs \
        libgcc \
        libstdc++ \
        tzdata \
        jq; \
    \
    # Create group
    if ! getent group jackett >/dev/null 2>&1; then \
        addgroup -g ${gid} jackett; \
    fi; \
    \
    # Create user
    adduser -D -H -u ${uid} -G jackett jackett; \
    \
    mkdir -p /opt/Jackett /config; \
    \
    # Fetch latest release
    tag=$(curl -s https://api.github.com/repos/VuzzyM/Jackett/releases/latest | jq -r .tag_name); \
    echo "Using tag: $tag"; \
    \
    # Download MUSL ARM64 build
    curl -fL -o /tmp/jackett.tar.gz \
        https://github.com/VuzzyM/Jackett/releases/download/${tag}/Jackett.Binaries.LinuxMuslARM64.tar.gz; \
    \
    tar xf /tmp/jackett.tar.gz -C /opt/Jackett --strip-components=1; \
    \
    chown -R jackett:jackett /opt/Jackett /config; \
    rm -rf /tmp/*

EXPOSE 9117

USER jackett
WORKDIR /config
VOLUME ["/config", "/data"]

CMD ["/opt/Jackett/jackett", "--NoUpdates"]
