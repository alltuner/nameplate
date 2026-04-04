#!/bin/sh
# ABOUTME: Renders the Corefile template with environment variables and starts CoreDNS.
# ABOUTME: Runs envsubst to replace placeholders, then execs CoreDNS as PID 1.

set -e

envsubst < /etc/coredns/Corefile.template > /etc/coredns/Corefile

if [ -n "${UPSTREAM_DNS}" ]; then
    sed -i '/^}$/i\    forward . '"${UPSTREAM_DNS}" /etc/coredns/Corefile
fi

echo "Starting CoreDNS with configuration:"
cat /etc/coredns/Corefile
echo "---"

exec coredns -conf /etc/coredns/Corefile -dns.port "${DNS_PORT}"
