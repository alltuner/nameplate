# ABOUTME: Multi-stage build that compiles CoreDNS with the coredns-tailscale plugin.
# ABOUTME: Produces a minimal image with sed-based runtime Corefile templating.

FROM --platform=$BUILDPLATFORM golang:1.26-alpine@sha256:2389ebfa5b7f43eeafbd6be0c3700cc46690ef842ad962f6c5bd6be49ed82039 AS builder

# COREDNS_VERSION must match the upstream version that plugin.cfg is based on.
# To upgrade, update both plugin.cfg and this value together.
ARG COREDNS_VERSION=v1.14.2
ARG COREDNS_TAILSCALE_VERSION=v0.3.22
ARG TARGETOS=linux
ARG TARGETARCH

ENV GOTOOLCHAIN=auto

WORKDIR /build

RUN wget -qO- https://github.com/coredns/coredns/archive/refs/tags/${COREDNS_VERSION}.tar.gz | \
    tar xz --strip-components=1

COPY plugin.cfg .

RUN go mod edit -require github.com/damomurf/coredns-tailscale@${COREDNS_TAILSCALE_VERSION} && \
    go generate && \
    go mod tidy

RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -o coredns

FROM alpine:3.23@sha256:25109184c71bdad752c8312a8623239686a9a2071e8825f20acb8f2198c3f659

COPY --chmod=755 --from=builder /build/coredns /usr/local/bin/coredns
COPY --chmod=755 entrypoint.sh /entrypoint.sh
COPY Corefile.template /etc/coredns/Corefile.template

EXPOSE 53/tcp 53/udp

ENTRYPOINT ["/entrypoint.sh"]
