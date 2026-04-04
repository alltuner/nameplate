# Nameplate

A Docker-based CoreDNS server that automatically creates DNS records for all machines in your Tailscale network (tailnet) under a custom domain. Uses the [coredns-tailscale](https://github.com/damomurf/coredns-tailscale) plugin to read machine information directly from the Tailscale daemon socket, with no API tokens required.

For example, a machine named `media-server` in your tailnet becomes resolvable as `media-server.internal.example.com` from any device on the tailnet.

## How it works

CoreDNS runs with the `coredns-tailscale` plugin compiled in. The plugin connects to the Tailscale daemon socket (mounted into the container) and queries the local API to discover all machines visible to the host. It then serves A and AAAA records for each machine under your configured domain.

This is designed as a **split DNS** setup: Tailscale routes only your custom domain's queries to this server, while all other DNS queries continue to use your normal DNS resolver.

### CoreDNS plugins

The Corefile includes the following plugins:

| Plugin | Purpose |
|---|---|
| **tailscale** | Queries the Tailscale local API via the daemon socket and serves A/AAAA records for each machine in the tailnet. Supports CNAME aliases via Tailscale ACL tags (see [CNAME aliases](#cname-aliases)). |
| **cache** | Caches DNS responses for `CACHE_TTL` seconds (default 30). Reduces load on the Tailscale socket and speeds up repeated lookups. |
| **log** | Logs all queries to stdout. Useful for debugging. Can be removed in production if you find it too noisy. |
| **errors** | Logs errors to stdout. |
| **health** | Exposes an HTTP health check at `/health` on `HEALTH_PORT` (default 8080). Used by the Docker healthcheck. |
| **ready** | Exposes an HTTP readiness check at `/ready` on `READY_PORT` (default 8181). Reports 200 once all plugins are loaded. |

## Quick start

A pre-built multi-arch image (amd64/arm64) is available at `ghcr.io/alltuner/nameplate`.

1. **Clone and configure:**

   ```bash
   git clone <repo-url> && cd nameplate
   cp docker-compose.example.yml docker-compose.yml
   cp .env.example .env
   # Edit .env to match your setup
   ```

   To build locally instead, edit `docker-compose.yml`: uncomment `build: .` and comment out the `image` line.

2. **Start the server:**

   ```bash
   docker compose up -d
   ```

3. **Verify it works:**

   ```bash
   dig @localhost my-machine.internal.example.com
   ```

4. **Configure Tailscale split DNS** (see below).

## Configuration

All settings are controlled via environment variables. Copy `.env.example` to `.env` and adjust:

| Variable | Default | Description |
|---|---|---|
| `DOMAIN` | `internal.example.com` | The domain under which tailnet machines are served |
| `DNS_PORT` | `53` | Port CoreDNS listens on (TCP and UDP) |
| `TAILSCALE_SOCKET_PATH` | `/var/run/tailscale/tailscaled.sock` | Path to the Tailscale socket on the host |
| `CACHE_TTL` | `30` | DNS cache duration in seconds |
| `HEALTH_PORT` | `8080` | Port for the health check HTTP endpoint |
| `READY_PORT` | `8181` | Port for the readiness check HTTP endpoint |
| `UPSTREAM_DNS` | *(empty)* | Upstream DNS server for forwarding unmatched queries (e.g., `1.1.1.1` or `100.100.100.100` for Tailscale MagicDNS). Leave empty to disable forwarding. |

## Configuring Tailscale split DNS

Split DNS tells Tailscale to route DNS queries for a specific domain to a nameserver you control, while leaving all other queries untouched. This is how you make `*.internal.example.com` resolve on every device in your tailnet.

### Step 1: Note the Tailscale IP of your CoreDNS host

On the machine running this container:

```bash
tailscale ip -4
```

Note this IP (e.g., `100.64.x.x`). This is the address Tailscale will send DNS queries to.

### Step 2: Configure split DNS in the Tailscale admin console

1. Go to the [Tailscale admin console](https://login.tailscale.com/admin/dns).
2. Scroll to **Nameservers**.
3. Under **Add nameserver**, select **Custom...**.
4. Click **Add Split DNS**.
5. Enter:
   - **Domain:** your configured `DOMAIN` (e.g., `internal.example.com`)
   - **Nameserver:** the Tailscale IP from Step 1
6. Save.

### Step 3: Verify from another device on the tailnet

From any machine on your tailnet:

```bash
dig my-machine.internal.example.com
```

You should see an A record pointing to the machine's Tailscale IP.

### Troubleshooting split DNS

- **Queries not reaching CoreDNS:** Ensure the CoreDNS host's Tailscale IP is correct and the container is running. Check `docker compose logs`.
- **SERVFAIL responses:** The Tailscale socket might not be accessible. Verify the socket path in `.env` matches the actual location on your host. On Linux it's typically `/var/run/tailscale/tailscaled.sock`, on macOS it's `/Library/Tailscale/tailscaled.sock`.
- **Stale results:** Increase `CACHE_TTL` if you want longer caching, or decrease it if machines are being added/removed frequently.
- **Port conflicts:** If port 53 is already in use (common on Linux with systemd-resolved), change `DNS_PORT` to another port and update the split DNS nameserver entry to include the port (e.g., `100.64.x.x:5353`).

## CNAME aliases

The `coredns-tailscale` plugin supports CNAME records via Tailscale ACL tags. Add a tag prefixed with `cname-` to any machine in your [Tailscale ACL policy](https://login.tailscale.com/admin/acls):

```jsonc
{
  "tagOwners": {
    "tag:cname-git": ["autogroup:admin"],
  },
}
```

Then apply the tag to a machine. This creates a CNAME record:

```
git.internal.example.com -> my-server.internal.example.com
```

This is useful for giving friendly names to services running on specific machines.

## Credits

Nameplate is a thin packaging layer around two excellent projects:

- **[CoreDNS](https://coredns.io/)** ([GitHub](https://github.com/coredns/coredns)) - A flexible, plugin-based DNS server written in Go, graduated from the CNCF.
- **[coredns-tailscale](https://github.com/damomurf/coredns-tailscale)** by [@damomurf](https://github.com/damomurf) - The CoreDNS plugin that makes Tailnet machine discovery and CNAME aliasing possible.

## Build arguments

The Dockerfile accepts build arguments for pinning versions:

| Argument | Default | Description |
|---|---|---|
| `COREDNS_VERSION` | `v1.14.2` | CoreDNS release tag |
| `COREDNS_TAILSCALE_VERSION` | `v0.3.21` | coredns-tailscale plugin version |

```bash
docker compose build --build-arg COREDNS_VERSION=v1.14.2
```

## Further reading

- [HTTPS with Let's Encrypt](docs/https-letsencrypt.md) - How to add TLS certificates to services on your custom internal domain.
- [Alternative approaches](docs/alternatives.md) - Lighter DNS servers, the Tailscale local API, and the ecosystem landscape.
