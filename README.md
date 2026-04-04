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

1. **Clone and configure:**

   ```bash
   git clone <repo-url> && cd nameplate
   cp .env.example .env
   # Edit .env to match your setup
   ```

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
| `COREDNS_VERSION` | `v1.12.0` | CoreDNS release tag |
| `COREDNS_TAILSCALE_VERSION` | `latest` | coredns-tailscale plugin version |

```bash
docker compose build --build-arg COREDNS_VERSION=v1.12.0
```

## HTTPS with Let's Encrypt (future consideration)

Nameplate solves DNS resolution for your tailnet, but services exposed over HTTP still lack TLS. This section sketches how you could add HTTPS certificates for `*.internal.example.com` using Let's Encrypt.

### The challenge

Your services live on private Tailscale IPs (100.x.x.x). Let's Encrypt's HTTP-01 challenge requires reaching your server from the public internet, which won't work here. The solution is **DNS-01 validation**, where you prove domain ownership by creating a TXT record in your public DNS, no inbound connectivity required.

### Recommended approach: Caddy as a reverse proxy

[Caddy](https://caddyserver.com/) handles TLS certificates automatically, including DNS-01 challenges, with minimal configuration. You'd run Caddy on each machine (or on a dedicated gateway machine) that needs to expose HTTPS services.

**User perspective, end to end:**

1. **Prerequisites:** You control the public DNS for `example.com` (e.g., via Cloudflare, Route53, etc.) and have an API token for your DNS provider.

2. **Run Caddy on the machine hosting your service** with a Caddyfile like:

   ```
   git.internal.example.com {
       reverse_proxy localhost:3000
       tls {
           dns cloudflare {env.CLOUDFLARE_API_TOKEN}
       }
   }
   ```

3. **What happens behind the scenes:**
   - Caddy requests a certificate from Let's Encrypt for `git.internal.example.com`
   - Let's Encrypt asks for a DNS-01 challenge: "create a TXT record at `_acme-challenge.git.internal.example.com`"
   - Caddy uses the Cloudflare API (or whichever provider) to create that TXT record in your **public** DNS
   - Let's Encrypt verifies the TXT record and issues the certificate
   - Caddy serves your service over HTTPS with automatic renewal

4. **From any tailnet device**, `https://git.internal.example.com` just works, with a valid certificate and no browser warnings.

### Alternative: wildcard certificate

Instead of per-service certificates, you can issue a single wildcard cert for `*.internal.example.com`:

```bash
certbot certonly \
    --dns-cloudflare \
    --dns-cloudflare-credentials /path/to/cloudflare.ini \
    -d "*.internal.example.com"
```

Then distribute the cert to your services (nginx, Traefik, etc.). Simpler to manage centrally, but you'll need to handle renewal and distribution yourself.

### What about Tailscale's built-in HTTPS?

Tailscale offers automatic HTTPS certificates via `tailscale cert`, but these use your `*.ts.net` tailnet domain (e.g., `machine.tail1234.ts.net`), not your custom domain. If you're fine with the `ts.net` domain, that's the zero-config option. Nameplate is for when you want your own domain hierarchy.

### Key requirement

Whichever approach you choose, your **public** DNS provider must support API-driven record management for DNS-01 challenges. Caddy and certbot both support most major providers (Cloudflare, Route53, Google Cloud DNS, DigitalOcean, etc.).
