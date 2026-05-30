FROM ghcr.io/home-assistant/home-assistant:stable

RUN mkdir -p /config /media /share && \
    chgrp -R 0 /config /media /share /tmp && \
    chmod -R g=u /config /media /share /tmp

USER 1001
