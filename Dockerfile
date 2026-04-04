# ABOUTME: Multi-stage build that compiles CoreDNS with the coredns-tailscale plugin.
# ABOUTME: Produces a minimal image with envsubst for runtime Corefile templating.

FROM golang:1.26-alpine AS builder

ARG COREDNS_VERSION=v1.14.2
ARG COREDNS_TAILSCALE_VERSION=v0.3.21

ENV GOTOOLCHAIN=auto

RUN apk add --no-cache git

WORKDIR /build

RUN git clone --depth 1 --branch ${COREDNS_VERSION} https://github.com/coredns/coredns.git .

# Add the tailscale plugin to the plugin list and regenerate imports.
RUN sed -i '/^log:log/a tailscale:github.com/damomurf/coredns-tailscale' plugin.cfg && \
    go get github.com/damomurf/coredns-tailscale@${COREDNS_TAILSCALE_VERSION} && \
    go generate

# Download dependencies in a separate layer so they are cached
# independently of code changes.
RUN go mod tidy && go mod download

RUN CGO_ENABLED=0 go build -o coredns

FROM alpine:3.23

RUN apk add --no-cache gettext

COPY --from=builder /build/coredns /usr/local/bin/coredns
COPY entrypoint.sh /entrypoint.sh
COPY Corefile.template /etc/coredns/Corefile.template

RUN chmod +x /entrypoint.sh

EXPOSE 53/tcp 53/udp

ENTRYPOINT ["/entrypoint.sh"]
