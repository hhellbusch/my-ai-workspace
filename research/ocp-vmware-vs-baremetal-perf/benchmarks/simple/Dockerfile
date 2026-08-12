# Sysbench image for OCP benchmark Jobs (CPU + memory only)
#
# Registry: https://quay.io/repository/rh_hhellbusch/sysbench
#
#   podman build -t quay.io/rh_hhellbusch/sysbench:1.0.20 .
#   podman push quay.io/rh_hhellbusch/sysbench:1.0.20
#
# Security: multi-stage build on UBI micro — no EPEL, no MariaDB client libs,
# no curl in the runtime image. Sysbench built with --without-mysql.

# -----------------------------------------------------------------------------
# Build sysbench from upstream source (1.0.20)
# -----------------------------------------------------------------------------
FROM registry.access.redhat.com/ubi9/ubi:latest AS builder

ARG SYSBENCH_VERSION=1.0.20

RUN dnf install -y \
      gcc gcc-c++ make automake libtool openssl-devel \
      git tar gzip which findutils && \
    dnf clean all

RUN curl -fsSL \
      "https://github.com/akopytov/sysbench/archive/refs/tags/${SYSBENCH_VERSION}.tar.gz" \
      | tar xz -C /tmp

WORKDIR /tmp/sysbench-${SYSBENCH_VERSION}

# CPU/memory benchmarks only — drops MariaDB/PostgreSQL client dependencies.
RUN ./autogen.sh && \
    ./configure --without-mysql --prefix=/usr/local && \
    make -j"$(nproc)" && \
    make install DESTDIR=/opt/stage

RUN /opt/stage/usr/local/bin/sysbench --version > /opt/stage/sysbench-version.txt

# -----------------------------------------------------------------------------
# Minimal runtime — UBI micro + sysbench binary + glibc runtime only
# -----------------------------------------------------------------------------
FROM registry.access.redhat.com/ubi9/ubi-micro:latest

LABEL maintainer="platform-team" \
      org.opencontainers.image.source="https://github.com/akopytov/sysbench" \
      org.opencontainers.image.description="sysbench 1.0.20 (cpu/memory) on UBI 9 micro"

COPY --from=builder /opt/stage/usr/local/bin/sysbench /usr/bin/sysbench
COPY --from=builder /opt/stage/sysbench-version.txt /etc/sysbench-version.txt

# Dynamic linker + libc runtime from builder (sysbench --without-mysql has no DB deps).
COPY --from=builder /lib64/ld-linux-x86-64.so.2 /lib64/
COPY --from=builder /lib64/libm.so.6 /lib64/
COPY --from=builder /lib64/libgcc_s.so.1 /lib64/
COPY --from=builder /lib64/libc.so.6 /lib64/

# Standard non-root UID for distroless/micro-style images.
USER 65532:65532

ENTRYPOINT ["/usr/bin/sysbench"]
