# ENV DERP_DOMAIN your-hostname.com

FROM golang:alpine AS builder
RUN go install tailscale.com/cmd/derper@main

# FROM alpine
FROM tailscale/tailscale:stable
WORKDIR /app

# ========= CONFIG =========
# - derper args
ENV DERP_DOMAIN your-hostname.com
ENV DERP_ADDR :443
ENV DERP_HTTP_PORT 80
ENV DERP_HOST=127.0.0.1
ENV DERP_CERTS=/app/certs
ENV DERP_STUN true
ENV DERP_VERIFY_CLIENTS false
# =========================

RUN apk upgrade --update-cache --available && \
    apk add openssl && \
    rm -rf /var/cache/apk/*

COPY --from=builder /go/bin/derper .
COPY scripts/init_derp.sh /app/

# build self-signed certs && start derper
CMD sh /app/init_derp.sh && \
    # https://github.com/tailscale/tailscale/issues/2794
    /app/derper \
    -a $DERP_ADDR \
    --hostname=$DERP_DOMAIN \
    --stun=$DERP_STUN  \
    --verify-clients=$DERP_VERIFY_CLIENTS
