FROM golang:alpine AS builder
ARG TAILSCALE_VERSION=v1.104.7

ENV CGO_ENABLED=0
RUN go install -ldflags="-s -w" \
    tailscale.com/cmd/derper@${TAILSCALE_VERSION} \
    tailscale.com/cmd/tailscale@${TAILSCALE_VERSION} \
    tailscale.com/cmd/tailscaled@${TAILSCALE_VERSION}

FROM alpine:latest
WORKDIR /app

ENV DERP_DOMAIN=derp.local \
    DERP_ADDR=:443 \
    DERP_HTTP_PORT=80 \
    DERP_STUN=true \
    DERP_CERTS=/app/certs \
    TS_STATE=mem:

RUN apk add --no-cache openssl ca-certificates curl

COPY --from=builder /go/bin/derper /go/bin/tailscale /go/bin/tailscaled /usr/bin/
COPY --chmod=0755 entrypoint.sh /app/entrypoint.sh

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
    CMD tailscale status >/dev/null 2>&1 || { kill 1; exit 1; }

ENTRYPOINT ["/app/entrypoint.sh"]
