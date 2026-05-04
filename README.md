<h1 align="center">Nameplate</h1>

<p align="center">
  <strong>DNS for your tailnet.</strong><br>
  A Docker-based CoreDNS server that turns every machine in your Tailscale network into a name under a custom domain.
</p>

<p align="center">
  <a href="https://alltuner.com/sponsor">Sponsor</a>
</p>

<p align="center">
  <img src="https://img.shields.io/github/license/alltuner/nameplate?color=5B2333" alt="License">
  <img src="https://img.shields.io/github/stars/alltuner/nameplate?color=5B2333" alt="Stars">
</p>

---

## Get Started

A pre-built multi-arch image (amd64/arm64) is published at `ghcr.io/alltuner/nameplate`.

1. Create a `docker-compose.yml`:

   ```yaml
   services:
     coredns:
       image: ghcr.io/alltuner/nameplate:latest
       container_name: nameplate
       ports:
         - "53:53/tcp"
         - "53:53/udp"
       volumes:
         - /var/run/tailscale/tailscaled.sock:/var/run/tailscale/tailscaled.sock:ro
       environment:
         DOMAIN: internal.example.com  # <-- replace with your domain
       restart: unless-stopped
       healthcheck:
         test: ["CMD", "wget", "-q", "--spider", "http://localhost:8080/health"]
         interval: 30s
         timeout: 5s
         retries: 3
   ```

2. Start the server:

   ```bash
   docker compose up -d
   ```

3. Verify:

   ```bash
   dig @localhost my-machine.internal.example.com
   ```

4. Configure Tailscale split DNS (see [below](#configuring-tailscale-split-dns)).

> **Building locally:** clone the repo and use `build: .` instead of `image:` in your compose file. See [Upgrading versions](#upgrading-versions) for details.

---

## What is Nameplate?

Nameplate runs CoreDNS with the [`coredns-tailscale`](https://github.com/damomurf/coredns-tailscale) plugin compiled in. The plugin reads your tailnet's machine list directly from the Tailscale daemon socket (no API tokens required) and serves A and AAAA records for each machine under a domain you configure.

A machine named `media-server` becomes `media-server.internal.example.com`, resolvable from any device on the tailnet.

This is designed as a **split DNS** setup: Tailscale routes only your custom domain's queries to Nameplate, while every other DNS query continues to use your normal resolver.

### CoreDNS plugins

| Plugin | Purpose |
|---|---|
| **tailscale** | Queries the Tailscale local API via the daemon socket and serves A/AAAA records for each machine in the tailnet. Supports CNAME aliases via Tailscale ACL tags (see [CNAME aliases](#cname-aliases)). |
| **cache** | Caches DNS responses for `CACHE_TTL` seconds (default 30). Reduces load on the Tailscale socket and speeds up repeated lookups. |
| **log** | Logs all queries to stdout. Useful for debugging. Can be removed in production if too noisy. |
| **errors** | Logs errors to stdout. |
| **health** | Exposes an HTTP health check at `/health` on `HEALTH_PORT` (default 8080). Used by the Docker healthcheck. |
| **ready** | Exposes an HTTP readiness check at `/ready` on `READY_PORT` (default 8181). Reports 200 once all plugins are loaded. |

## Configuration

All settings are environment variables. Copy `.env.example` to `.env` and adjust:

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

```bash
tailscale ip -4
```

Note this IP (e.g., `100.64.x.x`). This is where Tailscale will send DNS queries.

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

```bash
dig my-machine.internal.example.com
```

You should see an A record pointing to the machine's Tailscale IP.

### Troubleshooting split DNS

- **Queries not reaching CoreDNS:** ensure the CoreDNS host's Tailscale IP is correct and the container is running. Check `docker compose logs`.
- **SERVFAIL responses:** the Tailscale socket might not be accessible. Verify the socket path in `.env` matches the actual location on your host. On Linux it's typically `/var/run/tailscale/tailscaled.sock`, on macOS it's `/Library/Tailscale/tailscaled.sock`.
- **Stale results:** increase `CACHE_TTL` if you want longer caching, decrease it if machines are being added/removed frequently.
- **Port conflicts:** Tailscale split DNS only routes queries to port 53, so the server must listen on 53. If port 53 is already in use (common on Linux where systemd-resolved binds a stub listener to `127.0.0.53:53`), disable the stub listener by setting `DNSStubListener=no` in `/etc/systemd/resolved.conf` and restarting `systemd-resolved`.

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

Useful for giving friendly names to services running on specific machines.

## Upgrading versions

The CoreDNS version is pinned in the Dockerfile and must match the upstream version that `plugin.cfg` is based on. To upgrade CoreDNS, update both files together:

1. Generate a new `plugin.cfg` from the target CoreDNS release (adding the `tailscale` line).
2. Update `COREDNS_VERSION` in the Dockerfile to match.

The `COREDNS_TAILSCALE_VERSION` build argument can be overridden independently:

```bash
docker compose build --build-arg COREDNS_TAILSCALE_VERSION=v0.3.22
```

## Further reading

- [HTTPS with Let's Encrypt](docs/https-letsencrypt.md) — how to add TLS certificates to services on your custom internal domain.
- [Alternative approaches](docs/alternatives.md) — lighter DNS servers, the Tailscale local API, and the ecosystem landscape.

## Credits

Nameplate is a thin packaging layer around two excellent projects:

- **[CoreDNS](https://coredns.io/)** ([GitHub](https://github.com/coredns/coredns)) — a flexible, plugin-based DNS server written in Go, graduated from the CNCF.
- **[coredns-tailscale](https://github.com/damomurf/coredns-tailscale)** by [@damomurf](https://github.com/damomurf) — the CoreDNS plugin that makes tailnet machine discovery and CNAME aliasing possible.

## License

[MIT](LICENSE)

## Support the project

Nameplate is an open source project built by [David Poblador i Garcia](https://davidpoblador.com/) through [All Tuner Labs](https://www.alltuner.com/).

If this project was useful to you, [consider supporting its development](https://alltuner.com/sponsor).

---

<p align="center">
  Built by <a href="https://davidpoblador.com">David Poblador i Garcia</a> with the support of <a href="https://alltuner.com">All Tuner Labs</a>.<br>
  Made with ❤️ in Poblenou, Barcelona.
</p>
