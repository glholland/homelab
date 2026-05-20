# Stage 1: build ssocr (seven-segment OCR for camera integrations)
FROM registry.access.redhat.com/ubi9 AS ssocr-builder
RUN dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm && \
    dnf install -y gcc imlib2-devel make git && \
    git clone --depth 1 https://github.com/auerswal/ssocr /build/ssocr && \
    make -C /build/ssocr

# Stage 2: build libcec (HDMI-CEC for media player integrations)
FROM registry.access.redhat.com/ubi9 AS libcec-builder
RUN dnf config-manager --enable crb && \
    dnf install -y gcc-c++ cmake make git libudev-devel && \
    git clone --depth 1 https://github.com/Pulse-Eight/platform /build/platform && \
    cmake -B /build/platform/build /build/platform && cmake --build /build/platform/build && \
    cmake --install /build/platform/build && \
    git clone --depth 1 https://github.com/Pulse-Eight/libcec /build/libcec && \
    cmake -B /build/libcec/build /build/libcec && cmake --build /build/libcec/build

# Stage 3: fetch static ffmpeg (not in standard UBI repos)
FROM registry.access.redhat.com/ubi9-minimal AS ffmpeg-fetch
RUN microdnf install -y tar xz curl && \
    curl -sL https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz | \
    tar -xJ --strip-components=1 -C /tmp \
        --wildcards '*/ffmpeg' '*/ffprobe'

# Final stage: ubi9-minimal runtime
FROM registry.access.redhat.com/ubi9-minimal

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    HOME=/config

RUN microdnf install -y \
      python3.12 python3.12-pip \
      openssl ca-certificates \
      glibc libgcc libstdc++ \
      systemd-libs \
      bluez-libs \
      libnl3 \
      net-tools iproute \
    && microdnf clean all \
    && rm -rf /var/cache/dnf

COPY --from=ssocr-builder /build/ssocr/ssocr /usr/local/bin/ssocr
COPY --from=libcec-builder /build/libcec/build/src/libcec.so* /usr/local/lib/
COPY --from=libcec-builder /build/libcec/build/src/cec-client /usr/local/bin/cec-client
COPY --from=ffmpeg-fetch /tmp/ffmpeg /usr/local/bin/ffmpeg
COPY --from=ffmpeg-fetch /tmp/ffprobe /usr/local/bin/ffprobe

RUN ldconfig /usr/local/lib

RUN pip3.12 install --no-cache-dir homeassistant

RUN mkdir -p /config /media /share && \
    chgrp -R 0 /config /media /share /tmp && \
    chmod -R g=u /config /media /share /tmp

EXPOSE 8123
USER 1000
ENTRYPOINT ["python3.12", "-m", "homeassistant", "--config", "/config"]
