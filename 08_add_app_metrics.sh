#!/bin/bash
set -euo pipefail

# Добавление метрик приложения ComplexesMonitoringTCU-M в Prometheus
# Скрипт идемпотентен: повторный запуск не создаст дубликат job'а

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

SERVER_IP=$(detect_server_ip)
PROMETHEUS_CONFIG="/monitoring/prometheus/prometheus.yml"

# === Параметры приложения (при необходимости менять здесь) ===
APP_JOB_NAME="ComplexesMonitoringTCU-M"
APP_HOST="192.168.192.147"
APP_PORTS=(9101 9102 9103 9104)
# =============================================================

echo "========================================="
echo "Добавление метрик приложения ${APP_JOB_NAME}"
echo "IP адрес сервера: ${SERVER_IP}"
echo "========================================="

# Проверяем наличие конфигурации Prometheus
if [ ! -f "${PROMETHEUS_CONFIG}" ]; then
    echo "ОШИБКА: ${PROMETHEUS_CONFIG} не найден." >&2
    echo "Сначала запустите 03_install_prometheus.sh" >&2
    exit 1
fi

# Проверяем, что контейнер Prometheus запущен
if ! docker ps --format '{{.Names}}' | grep -q '^prometheus$'; then
    echo "ОШИБКА: контейнер prometheus не запущен." >&2
    echo "Сначала запустите 03_install_prometheus.sh" >&2
    exit 1
fi

# Идемпотентность: пропускаем добавление, если job уже есть
if grep -q "job_name: '${APP_JOB_NAME}'" "${PROMETHEUS_CONFIG}"; then
    echo "Job '${APP_JOB_NAME}' уже есть в конфигурации — пропускаем добавление"
else
    # Дополняем секцию scrape_configs (append корректен: scrape_configs — последняя
    # верхнеуровневая секция в конфиге, генерируемом 03_install_prometheus.sh)
    cat >> "${PROMETHEUS_CONFIG}" << EOF

  # Метрики приложения ${APP_JOB_NAME}
  - job_name: '${APP_JOB_NAME}'
    static_configs:
      - targets:
$(for port in "${APP_PORTS[@]}"; do echo "          - '${APP_HOST}:${port}'"; done)
EOF
    echo "Job '${APP_JOB_NAME}' добавлен в ${PROMETHEUS_CONFIG}"
fi

# Проверяем валидность конфигурации перед перезапуском
echo "Проверка конфигурации promtool..."
docker exec prometheus promtool check config /etc/prometheus/prometheus.yml

# Перезапускаем Prometheus для применения конфигурации
echo "Перезапуск Prometheus..."
docker restart prometheus

# Ждем готовности Prometheus
wait_for_url "http://localhost:9090/-/ready" "Prometheus" 30

echo "========================================="
echo "Проверка доступности endpoints приложения:"
for port in "${APP_PORTS[@]}"; do
    if curl -fsS --max-time 5 "http://${APP_HOST}:${port}/metrics" > /dev/null 2>&1; then
        echo "  http://${APP_HOST}:${port}/metrics -> доступен"
    else
        echo "  http://${APP_HOST}:${port}/metrics -> НЕДОСТУПЕН (проверьте приложение)"
    fi
done

echo ""
echo "Состояние targets в Prometheus:"
for port in "${APP_PORTS[@]}"; do
    HEALTH=$(curl -fsS "http://localhost:9090/api/v1/targets" 2>/dev/null \
        | jq -r --arg url "http://${APP_HOST}:${port}/metrics" \
            '.data.activeTargets[] | select(.scrapeUrl == $url) | .health' 2>/dev/null || true)
    echo "  ${APP_HOST}:${port} -> ${HEALTH:-не найден в targets}"
done

echo ""
echo "========================================="
echo "Метрики приложения ${APP_JOB_NAME} добавлены"
echo "Prometheus Targets: http://${SERVER_IP}:9090/targets"
echo "========================================="
