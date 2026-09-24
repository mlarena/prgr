# Настройка дашбордов в Grafana

Руководство по настройке дашбордов для стека мониторинга.

## Текущая конфигурация Prometheus

Конфигурационный файл: `/monitoring/prometheus/prometheus.yml` (на сервере
мониторинга 192.168.192.130). Актуальное состояние после запуска всех скриптов
и добавления job'а postgres_exporter:

```yaml
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

  # Мониторинг хоста через node_exporter (сервер, который мониторим)
  - job_name: 'node_exporter'
    static_configs:
      - targets: ['192.168.192.147:9100']

  # Метрики приложения ComplexesMonitoringTCU-M (dotnet-приложение,
  # метрики формата prometheus-net: process_*, dotnet_*, http_*)
  - job_name: 'ComplexesMonitoringTCU-M'
    static_configs:
      - targets:
          - '192.168.192.147:9101'
          - '192.168.192.147:9102'
          - '192.168.192.147:9103'
          - '192.168.192.147:9104'

  # Метрики postgres
  - job_name: 'postgres_exporter'
    static_configs:
      - targets:
          - '192.168.192.147:9187'
```

После изменения конфига проверить его и перезапустить Prometheus:

```bash
docker exec prometheus promtool check config /etc/prometheus/prometheus.yml
docker restart prometheus
```

Состояние всех targets: http://192.168.192.130:9090/targets

## Где что смотреть

| Что | Где |
|---|---|
| Prometheus (targets, запросы) | http://192.168.192.130:9090 |
| Grafana | http://192.168.192.130:3000 (admin/admin) |
| Метрики dotnet-приложения (сырые) | http://192.168.192.147:9101..9104/metrics |
| Метрики node_exporter (сырые) | http://192.168.192.147:9100/metrics |
| Метрики postgres (сырые) | http://192.168.192.147:9187/metrics |

## Как создать дашборд вручную

1. Открыть Grafana → боковое меню → **Dashboards** → **New dashboard**.
2. Нажать **Add visualization**, выбрать datasource **Prometheus**.
3. В поле запроса ввести PromQL-запрос (примеры ниже), настроить тип панели
   (Time series, Stat, Gauge, Table).
4. **Save dashboard** (Ctrl+S), задать имя, например «TCU-M Application».

Также можно импортировать готовый дашборд с grafana.com:
**Dashboards → New → Import** → ввести ID дашборда → Load → выбрать
datasource Prometheus. Готовые дашборды:

- **1860** — Node Exporter Full (уже импортирован скриптом `06_import_dashboard.sh`);
- **9628** — PostgreSQL Database;
- для dotnet-приложений готовых официальных дашбордов мало, обычно собирают
  вручную — запросы см. ниже.

## PromQL-запросы для dotnet-приложения (ComplexesMonitoringTCU-M)

Приложение использует библиотеку prometheus-net (стандарт для .NET), поэтому
метрики называются `dotnet_*`, `process_*`, `http_*`. Все запросы можно
фильтровать по инстансу (`instance="192.168.192.147:9101"`) — так как
приложение слушает 4 порта, чаще всего агрегируют через `sum by`.

### CPU приложения

```promql
# CPU (ядра) по всем 4 инстансам приложения
sum(rate(process_cpu_seconds_total{job="ComplexesMonitoringTCU-M"}[2m])) by (instance)

# CPU в процентах
100 * sum(rate(process_cpu_seconds_total{job="ComplexesMonitoringTCU-M"}[2m])) by (instance)
```

### Память

```promql
# Рабочий набор (Working Set), байт
sum(process_working_set_bytes{job="ComplexesMonitoringTCU-M"}) by (instance)

# Общий объем памяти всех инстансов
sum(process_working_set_bytes{job="ComplexesMonitoringTCU-M"})

# Память .NET GC (heap)
sum(dotnet_total_memory_bytes{job="ComplexesMonitoringTCU-M"}) by (instance)

# Сборок GC поколения 2 в секунду
sum(rate(dotnet_gc_collection_count_total{job="ComplexesMonitoringTCU-M", generation="2"}[2m])) by (instance)
```

### Потоки и открытые файлы

```promql
# Количество потоков
sum(process_num_threads{job="ComplexesMonitoringTCU-M"}) by (instance)

# Открытые файловые дескрипторы
sum(process_open_fds{job="ComplexesMonitoringTCU-M"}) by (instance)
```

### HTTP-запросы (если приложение экспортирует http-метрики)

```promql
# RPS по кодам ответа
sum(rate(http_requests_received_total{job="ComplexesMonitoringTCU-M"}[2m])) by (code)

# RPS по методам и эндпоинтам
sum(rate(http_requests_received_total{job="ComplexesMonitoringTCU-M"}[2m])) by (method, route)

# Процент ошибок (5xx)
100 * sum(rate(http_requests_received_total{job="ComplexesMonitoringTCU-M", code=~"5.."}[2m]))
  / sum(rate(http_requests_received_total{job="ComplexesMonitoringTCU-M"}[2m]))

# Средняя длительность запроса
sum(rate(http_request_duration_seconds_sum{job="ComplexesMonitoringTCU-M"}[2m]))
  / sum(rate(http_requests_received_total{job="ComplexesMonitoringTCU-M"}[2m]))
```

> Точный список доступных метрик зависит от версии prometheus-net и того,
> что экспортирует приложение. Посмотреть фактические имена:
> `curl http://192.168.192.147:9101/metrics | grep -v '^#'`

### Доступность инстансов

```promql
# up = 1, если Prometheus успешно скрейпит endpoint
up{job="ComplexesMonitoringTCU-M"}
```

## PromQL-запросы для PostgreSQL (postgres_exporter)

```promql
# Доступность БД
pg_up{job="postgres_exporter"}

# Активные соединения
pg_stat_database_numbackends{job="postgres_exporter"}

# Скорость транзакций (коммиты + откаты)
sum(rate(pg_stat_database_xact_commit{job="postgres_exporter"}[2m])) by (datname)
sum(rate(pg_stat_database_xact_rollback{job="postgres_exporter"}[2m])) by (datname)

# Конфликты и дедлоки
pg_stat_database_conflicts{job="postgres_exporter"}
pg_stat_database_deadlocks{job="postgres_exporter"}

# Размер базы
pg_database_size_bytes{job="postgres_exporter"}

# Кеш-хит (доля чтений из кеша, должно быть близко к 1)
sum(rate(pg_stat_database_blks_hit{job="postgres_exporter"}[2m]))
  / (sum(rate(pg_stat_database_blks_hit{job="postgres_exporter"}[2m]))
  + sum(rate(pg_stat_database_blks_read{job="postgres_exporter"}[2m])))
```

## PromQL-запросы для хоста (node_exporter)

```promql
# CPU хоста в процентах (среднее по ядрам)
100 - (avg by (instance) (rate(node_cpu_seconds_total{job="node_exporter", mode="idle"}[2m])) * 100)

# Использование RAM в процентах
100 * (1 - (node_memory_MemAvailable_bytes{job="node_exporter"} / node_memory_MemTotal_bytes{job="node_exporter"}))

# Диск: занято в процентах (корневая ФС)
100 * (1 - (node_filesystem_avail_bytes{job="node_exporter", mountpoint="/"} / node_filesystem_size_bytes{job="node_exporter", mountpoint="/"}))

# Сеть: входящий/исходящий трафик (байт/с)
rate(node_network_receive_bytes_total{job="node_exporter", device!="lo"}[2m])
rate(node_network_transmit_bytes_total{job="node_exporter", device!="lo"}[2m])

# Load average
node_load1{job="node_exporter"}
node_load5{job="node_exporter"}
node_load15{job="node_exporter"}
```

## Пример структуры дашборда «TCU-M Application»

Рекомендуемые панели (тип → запрос из разделов выше):

| Панель | Тип | Запрос |
|---|---|---|
| Instances up | Stat | `up{job="ComplexesMonitoringTCU-M"}` |
| CPU по инстансам | Time series | `100 * sum(rate(process_cpu_seconds_total{...}[2m])) by (instance)` |
| Memory по инстансам | Time series | `sum(process_working_set_bytes{...}) by (instance)` |
| GC heap | Time series | `sum(dotnet_total_memory_bytes{...}) by (instance)` |
| RPS по кодам ответа | Time series | `sum(rate(http_requests_received_total{...}[2m])) by (code)` |
| Error rate % | Stat | формула 5xx из раздела выше |
| Threads / FDs | Time series | `process_num_threads`, `process_open_fds` |

Вместо `{...}` — полный селектор `{job="ComplexesMonitoringTCU-M"}`.

## Переменные дашборда (удобно для 4 инстансов)

Чтобы фильтровать панели по конкретному инстансу приложения:

1. Настройки дашборда (шестерёнка) → **Variables** → **New**.
2. Name: `instance`, Type: `Query`.
3. Query: `label_values(up{job="ComplexesMonitoringTCU-M"}, instance)`.
4. В запросах панелей добавить фильтр:
   `{job="ComplexesMonitoringTCU-M", instance=~"$instance"}`.

При выборе «All» в переменной фильтр покроет все 4 порта.

## Проверка после настройки

```bash
# 1. Все ли targets в состоянии UP
curl -s http://localhost:9090/api/v1/targets | jq -r '.data.activeTargets[] | "\(.labels.job) \(.scrapeUrl) \(.health)"'

# 2. Что реально экспортирует приложение
curl http://192.168.192.147:9101/metrics | grep -v '^#' | head -30
```
