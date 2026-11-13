# Stage 1: Build a fully static, speed-optimized gotatun binary
FROM --platform=linux/amd64 rust:1-alpine AS builder

RUN apk add --no-cache \
    git \
    build-base \
    musl-dev \
    linux-headers

WORKDIR /src

# Build configuration:
#   - crt-static links musl libc into the binary, so it has no shared-library dependencies
#   - opt-level=3, fat LTO, and a single codegen unit favor packet-processing and crypto throughput
#   - panic=abort drops unwinding machinery for a smaller, faster binary
#   - strip=symbols minimizes the final image size
ENV RUSTFLAGS="-C target-feature=+crt-static" \
    CARGO_PROFILE_RELEASE_OPT_LEVEL=3 \
    CARGO_PROFILE_RELEASE_LTO=true \
    CARGO_PROFILE_RELEASE_CODEGEN_UNITS=1 \
    CARGO_PROFILE_RELEASE_PANIC=abort \
    CARGO_PROFILE_RELEASE_STRIP=symbols

ARG GOTATUN_VERSION=v0.10.3
ARG RUST_TARGET=x86_64-unknown-linux-musl

RUN git clone --depth 1 --branch "${GOTATUN_VERSION}" https://github.com/mullvad/gotatun.git . && \
    cargo build --release --bin gotatun --target "${RUST_TARGET}" && \
    install -Dm755 "target/${RUST_TARGET}/release/gotatun" /out/gotatun

# Stage 2: Minimal runtime image
FROM --platform=linux/amd64 alpine:latest

# Runtime needs only:
#   - wg: the small WireGuard CLI used to configure the tunnel
#   - iptables/ip6tables: NAT masquerading for IPv4 and IPv6
RUN apk add --no-cache \
    wireguard-tools-wg \
    iptables \
    ip6tables

COPY --from=builder /out/gotatun /usr/local/bin/gotatun
COPY --chmod=755 entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
