#!/bin/bash
# common.sh — shared functions for monitoring scripts
# Sourced via: source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Detect the primary server IP address (first non-loopback IPv4)
detect_server_ip() {
    ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -n1
}

# Wait until an HTTP service becomes available
# Usage: wait_for_url "http://host:3000/api/health" "Grafana" [max retries]
# Returns 0 on success, 1 if the service never became available
wait_for_url() {
    local url="$1"
    local name="${2:-service}"
    local max_retries="${3:-30}"
    local i=0

    while [ "$i" -lt "$max_retries" ]; do
        if curl -fsS --max-time 5 "$url" > /dev/null 2>&1; then
            echo "${name} is up"
            return 0
        fi
        echo "Waiting for ${name}... ($((i+1))/${max_retries})"
        sleep 2
        i=$((i+1))
    done

    echo "ERROR: ${name} did not become available after ${max_retries} attempts (${url})" >&2
    return 1
}

# Fetch the latest release version from GitHub
# Usage: get_latest_release "prometheus/node_exporter" "1.10.2"
# If the API is unavailable, the provided fallback is returned
get_latest_release() {
    local repo="$1"
    local fallback_version="$2"
    local version

    version=$(curl -fsSL --max-time 10 --retry 2 \
        "https://api.github.com/repos/${repo}/releases/latest" 2>/dev/null \
        | jq -r '.tag_name // empty' 2>/dev/null | sed 's/^v//') || version=""

    if [ -z "$version" ]; then
        echo "${fallback_version}"
    else
        echo "${version}"
    fi
}
