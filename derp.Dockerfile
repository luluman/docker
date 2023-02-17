# ENV DERP_DOMAIN your-hostname.com

FROM golang:alpine AS builder
RUN go install tailscale.com/cmd/derper@main

FROM alpine
WORKDIR /app

ENV DERP_DOMAIN your-hostname.com
ENV DERP_VERIFY_CLIENTS true

COPY --from=builder /go/bin/derper .

CMD /app/derper -hostname $DERP_DOMAIN -certmode manual -certdir /srv/certs -verify-clients=$DERP_VERIFY_CLIENTS
