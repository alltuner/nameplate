#!/bin/sh
# ABOUTME: Renders the Corefile template with environment variables and starts CoreDNS.
# ABOUTME: Uses sed to replace placeholders, then execs CoreDNS as PID 1.

set -e

sed \
    -e "s/\${DOMAIN}/${DOMAIN}/g" \
    -e "s/\${DNS_PORT}/${DNS_PORT}/g" \
    -e "s/\${CACHE_TTL}/${CACHE_TTL}/g" \
    -e "s/\${HEALTH_PORT}/${HEALTH_PORT}/g" \
    -e "s/\${READY_PORT}/${READY_PORT}/g" \
    /etc/coredns/Corefile.template > /etc/coredns/Corefile

if [ -n "${UPSTREAM_DNS}" ]; then
    sed -i '/^}$/i\    forward . '"${UPSTREAM_DNS}" /etc/coredns/Corefile
fi

echo "Starting CoreDNS with configuration:"
cat /etc/coredns/Corefile
echo "---"

exec coredns -conf /etc/coredns/Corefile -dns.port "${DNS_PORT}"
