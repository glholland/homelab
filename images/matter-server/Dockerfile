FROM ghcr.io/home-assistant-libs/python-matter-server:stable

RUN mkdir -p /data /data/credentials && \
    chgrp -R 0 /data && \
    chmod -R g=u /data

USER 568
