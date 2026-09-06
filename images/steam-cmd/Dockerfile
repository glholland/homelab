FROM registry.access.redhat.com/ubi9/ubi:latest

# Install 32-bit libraries required for steamcmd
# UBI9 requires enabling the codeready-builder or similar for some i686 packages if not in main,
# but glibc.i686 is usually available.
# Actually, for standard UBI, we might need to be careful. Fedora is often easier for 32-bit.
# Let's try Fedora first as it has easy access to i686 packages.
FROM fedora:latest

RUN dnf install -y \
    glibc.i686 \
    libstdc++.i686 \
    glibc-langpack-en \
    tar \
    curl \
    --setopt=install_weak_deps=False && \
    dnf clean all

ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

# Create workspace
WORKDIR /opt/steamcmd

# OKD Best Practice: Support arbitrary UIDs
# 1. Create the directory
# 2. Grant permissions to the root group (0)
# 3. We don't strictly need to create a specific user if we rely on OKD to assign one,
#    but running as a non-root user by default is good practice.
RUN mkdir -p /opt/steamcmd && \
    chgrp -R 0 /opt/steamcmd && \
    chmod -R g+rwX /opt/steamcmd

# Bootstrap steamcmd
# We use a script or just download it here.
RUN curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf - && \
    chgrp -R 0 /opt/steamcmd && \
    chmod -R g+rwX /opt/steamcmd

# Add to PATH
ENV PATH="/opt/steamcmd:${PATH}"

# Switch to non-root user
USER 1001

# Keep container running
CMD ["tail", "-f", "/dev/null"]
