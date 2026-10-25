# DayZ dedicated server (native Linux binary, app 223350).
# Compatible with both `podman build` and `docker build` (-f Containerfile).
FROM docker.io/steamcmd/steamcmd:latest

USER root
RUN useradd -m -s /bin/bash steam \
    && mkdir -p /opt/dayz/bin /opt/dayz/server /opt/dayz/config /opt/dayz/profiles \
    && chown -R steam:steam /opt/dayz

COPY --chmod=0755 scripts/entrypoint.sh scripts/install-mods.sh /opt/dayz/bin/

USER steam
ENV HOME=/home/steam

ENV DAYZ_SERVER_DIR=/opt/dayz/server \
    DAYZ_CONFIG_DIR=/opt/dayz/config \
    DAYZ_PROFILES_DIR=/opt/dayz/profiles \
    DAYZ_MODS_FILE=/opt/dayz/mods.txt \
    DAYZ_PORT=2302 \
    DAYZ_AUTO_UPDATE=1 \
    DAYZ_VALIDATE=0

# Game traffic: 2302-2306/udp, Steam browser query: 27016/udp
EXPOSE 2302-2306/udp 27016/udp

ENTRYPOINT ["/opt/dayz/bin/entrypoint.sh"]
