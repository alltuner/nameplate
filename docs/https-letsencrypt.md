# HTTPS with Let's Encrypt

Nameplate handles DNS resolution for your tailnet under a custom domain, but services exposed over HTTP still lack TLS. This guide sketches how you could add HTTPS certificates for `*.internal.example.com` using Let's Encrypt.

> **Note:** This is not a goal of Nameplate itself. This document is provided as a reference for users who want to layer HTTPS on top of their split DNS setup.

## The challenge

Your services live on private Tailscale IPs (100.x.x.x). Let's Encrypt's HTTP-01 challenge requires reaching your server from the public internet, which won't work here. The solution is **DNS-01 validation**, where you prove domain ownership by creating a TXT record in your public DNS, no inbound connectivity required.

## Recommended approach: Caddy as a reverse proxy

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

## Alternative: wildcard certificate

Instead of per-service certificates, you can issue a single wildcard cert for `*.internal.example.com`:

```bash
certbot certonly \
    --dns-cloudflare \
    --dns-cloudflare-credentials /path/to/cloudflare.ini \
    -d "*.internal.example.com"
```

Then distribute the cert to your services (nginx, Traefik, etc.). Simpler to manage centrally, but you'll need to handle renewal and distribution yourself.

## What about Tailscale's built-in HTTPS?

Tailscale offers automatic HTTPS certificates via `tailscale cert`, but these use your `*.ts.net` tailnet domain (e.g., `machine.tail1234.ts.net`), not your custom domain. If you're fine with the `ts.net` domain, that's the zero-config option. Nameplate is for when you want your own domain hierarchy.

## Key requirement

Whichever approach you choose, your **public** DNS provider must support API-driven record management for DNS-01 challenges. Caddy and certbot both support most major providers (Cloudflare, Route53, Google Cloud DNS, DigitalOcean, etc.).
