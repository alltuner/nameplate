# ABOUTME: Multi-stage build that compiles CoreDNS with the coredns-tailscale plugin.
# ABOUTME: Produces a minimal image with sed-based runtime Corefile templating.

FROM --platform=$BUILDPLATFORM golang:1.26-alpine AS builder

ARG COREDNS_VERSION=v1.14.2
ARG COREDNS_TAILSCALE_VERSION=v0.3.22

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

# Cross-compile a binary for each target platform so the Go compiler
# runs natively on the build host instead of under QEMU.
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o coredns-amd64
RUN CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -o coredns-arm64

FROM alpine:3.23

ARG TARGETARCH
COPY --chmod=755 --from=builder /build/coredns-${TARGETARCH} /usr/local/bin/coredns
COPY --chmod=755 entrypoint.sh /entrypoint.sh
COPY Corefile.template /etc/coredns/Corefile.template

EXPOSE 53/tcp 53/udp

ENTRYPOINT ["/entrypoint.sh"]
