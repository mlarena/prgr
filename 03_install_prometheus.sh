#!/bin/bash

# Получение IP из файла или автоматическое определение
if [ -f /tmp/server_ip.txt ]; then
    SERVER_IP=$(cat /tmp/server_ip.txt)
else
    SERVER_IP=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -n1)
fi

echo "========================================="
echo "Установка Prometheus"
echo "IP адрес сервера: ${SERVER_IP}"
echo "========================================="

# Создаем рабочую директорию
mkdir -p /monitoring/prometheus

# Создаем конфигурационный файл Prometheus с автоматической подстановкой IP
cat > /monitoring/prometheus/prometheus.yml << EOF
global:
  scrape_interval: 15s
  evaluation_interval: 15s

alerting:
  alertmanagers:
    - static_configs:
        - targets: []

rule_files: []

scrape_configs:
  # Мониторинг самого Prometheus
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  # Мониторинг хоста через node_exporter
  - job_name: 'node_exporter'
    static_configs:
      - targets: ['${SERVER_IP}:9100']
EOF

# Останавливаем и удаляем старый контейнер если существует
docker stop prometheus 2>/dev/null
docker rm prometheus 2>/dev/null

# Загружаем образ Prometheus (если еще нет)
echo "Проверка наличия образа Prometheus..."
if ! docker images prom/prometheus --format "{{.Repository}}" | grep -q prom/prometheus; then
    echo "Загрузка образа Prometheus..."
    docker pull prom/prometheus
else
    echo "Образ Prometheus уже загружен"
fi
# Запускаем Prometheus в Docker
docker run -d \  --name=prometheus \
  --restart unless-stopped \
  --network=host \
  -v /monitoring/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml \
  -v prometheus-data:/prometheus \
  prom/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/prometheus

echo "========================================="
echo "Установка Prometheus завершена"
echo "========================================="

# Проверяем запуск
sleep 3
docker ps | grep prometheus

echo "Prometheus доступен по адресу: http://${SERVER_IP}:9090"
echo "Prometheus Targets: http://${SERVER_IP}:9090/targets"