# Alternative approaches

Nameplate uses CoreDNS with the [coredns-tailscale](https://github.com/damomurf/coredns-tailscale) plugin. This works well but CoreDNS is a large project with many dependencies. This document surveys alternative approaches for serving DNS records from a Tailscale network.

## How the Tailscale local API works

All approaches ultimately need to discover machines on the tailnet. The Tailscale daemon exposes a local HTTP API over a Unix socket (on Linux: `/var/run/tailscale/tailscaled.sock`):

```bash
curl --unix-socket /var/run/tailscale/tailscaled.sock \
  http://local-tailscaled.sock/localapi/v0/status
```

This returns JSON containing every peer's hostname, Tailscale IPs (v4 and v6), online status, ACL tags, and more. No API tokens or authentication required, just access to the socket.

This is what `coredns-tailscale` uses internally, and what any alternative would use too.

## Existing projects

### Lightweight DNS servers

| Project | DNS Server | Tailscale Integration | Notes |
|---|---|---|---|
| [tailscale-custom-domain-dns](https://github.com/giodamelio/tailscale-custom-domain-dns) | Custom (standalone) | Local API | Closest to a minimal standalone solution. Personal project, not production-hardened. |
| [tailscale-dns-container](https://github.com/stumpylog/tailscale-dns-container) | dnsmasq | Tailscale API (token) | Docker-based. Uses API tokens rather than the local socket. |

### DNS sync tools

| Project | Approach | Notes |
|---|---|---|
| [tailscale-cloudflare-dnssync](https://github.com/marc1307/tailscale-cloudflare-dnssync) | Syncs tailnet IPs to Cloudflare DNS | Most mature option. Requires Cloudflare. Supports Headscale too. |

### CoreDNS plugins

| Project | Notes |
|---|---|
| [damomurf/coredns-tailscale](https://github.com/damomurf/coredns-tailscale) | What Nameplate uses. Most popular, supports CNAME via tags. |
| [cfunkhouser/coredns-tailscale](https://github.com/cfunkhouser/coredns-tailscale) | Tag-based zone support, configurable refresh intervals. |
| [christian-deleon/tailscale-coredns](https://github.com/christian-deleon/tailscale-coredns) | HA variant with nested subdomains via tags. |

## Building a custom lightweight server

The Tailscale local API is simple enough that a standalone DNS server is very feasible. The core logic is:

1. Query `/localapi/v0/status` via the Unix socket
2. Parse the JSON response, extract peer hostnames and IPs
3. Serve A/AAAA records as `<hostname>.<domain>`
4. Periodically re-poll to pick up new machines

A minimal implementation in Python (using `dnslib`) or Go (using `miekg/dns`) would be roughly 100-150 lines. This would eliminate the CoreDNS dependency entirely while keeping the local-socket approach (no API tokens needed).

### Tradeoffs vs. CoreDNS

| | CoreDNS + plugin | Custom lightweight server |
|---|---|---|
| **Dependencies** | Heavy (CoreDNS pulls in k8s, gRPC, protobuf, etc.) | Minimal (just a DNS library + HTTP client) |
| **Features** | Caching, health checks, metrics, logging built in | You build what you need |
| **Maintenance** | Plugin must track CoreDNS and Go version changes | You own it, but it's small |
| **Battle-tested** | CoreDNS is CNCF-graduated, widely deployed | New code, needs testing |
| **Image size** | ~50MB+ | Could be <10MB |

## Gap in the ecosystem

As of early 2026, there is no production-grade lightweight DNS server that reads the Tailscale local socket and serves custom domain records. The options are either CoreDNS-based (heavy) or personal projects (not hardened). This is a space where a focused tool could add value.
