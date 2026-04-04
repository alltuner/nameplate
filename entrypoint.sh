#!/bin/sh
# ABOUTME: Renders the Corefile template with environment variables and starts CoreDNS.
# ABOUTME: Runs envsubst to replace placeholders, then execs CoreDNS as PID 1.

set -e

envsubst < /etc/coredns/Corefile.template > /etc/coredns/Corefile

echo "Starting CoreDNS with configuration:"
cat /etc/coredns/Corefile
echo "---"

exec coredns -conf /etc/coredns/Corefile -dns.port "${DNS_PORT}"
