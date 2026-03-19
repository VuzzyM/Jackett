FROM debian:bookworm-slim
LABEL maintainer="Vuzzy"

ARG uid=1000
ARG gid=1000
ENV DEBIAN_FRONTEND=noninteractivex
ENV XDG_CONFIG_HOME=/config

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        libicu72 \
    && \
    # Ensure group with desired GID exists
    if getent group users; then \
        groupmod -g ${gid} users; \
    else \
        groupadd -g ${gid} users; \
    fi && \
    useradd --no-create-home -g users -u ${uid} jackett && \
    mkdir -p /opt/Jackett /config && \
    tag=$(curl -s https://api.github.com/repos/VuzzyM/Jackett/releases/latest \
        | awk -F'"' '/tag_name/{print $4;exit}') && \
    curl -L -o /tmp/jackett.tar.gz \
        https://github.com/VuzzyM/Jackett/releases/download/${tag}/Jackett.Binaries.LinuxARM64.tar.gz && \
    tar xf /tmp/jackett.tar.gz -C /opt/Jackett --strip-components=1 && \
    chown -R jackett:users /opt/Jackett /config && \
    apt-get purge -y --auto-remove curl && \
    rm -rf /var/lib/apt/lists /tmp/*

EXPOSE 9117
USER jackett
VOLUME ["/config", "/data"]
WORKDIR /config

CMD ["/opt/Jackett/jackett", "--NoUpdates"]
