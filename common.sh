#!/bin/bash
# common.sh — общие функции для скриптов мониторинга
# Подключается через: source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Определение основного IP-адреса сервера (первый не-loopback IPv4)
detect_server_ip() {
    ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -n1
}

# Ожидание доступности HTTP-сервиса
# Использование: wait_for_url "http://host:3000/api/health" "Grafana" [кол-во попыток]
# Возвращает 0 при успехе, 1 — если сервис так и не стал доступен
wait_for_url() {
    local url="$1"
    local name="${2:-service}"
    local max_retries="${3:-30}"
    local i=0

    while [ "$i" -lt "$max_retries" ]; do
        if curl -fsS --max-time 5 "$url" > /dev/null 2>&1; then
            echo "${name} готов к работе"
            return 0
        fi
        echo "Ожидание ${name}... ($((i+1))/${max_retries})"
        sleep 2
        i=$((i+1))
    done

    echo "ОШИБКА: ${name} не стал доступен за ${max_retries} попыток (${url})" >&2
    return 1
}

# Получение последней версии релиза с GitHub
# Использование: get_latest_release "prometheus/node_exporter" "1.10.2"
# Если API недоступен — возвращается переданный fallback
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
