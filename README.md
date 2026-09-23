# prgr — автоматизация развёртывания стека мониторинга

Набор скриптов для установки стека мониторинга на Debian (x86_64 и ARM).

## Архитектура

```
+-----------------------------+          +----------------------------------+
|  СЕРВЕР МОНИТОРИНГА         |          |  СЕРВЕР, КОТОРЫЙ МОНИТОРИМ       |
|  192.168.192.130            |          |  192.168.192.147                 |
|                             |  :9100   |                                  |
|  Prometheus :9090 <---------+----------+-- node_exporter                  |
|  Grafana    :3000           |  :9187   |                                  |
|                             <----------+-- postgres_exporter (опционально)|
|                             | :9101-4  |                                  |
|                             <----------+-- ComplexesMonitoringTCU-M       |
+-----------------------------+          +----------------------------------+
```

| Компонент | Где установлен | Порт | Способ установки |
|---|---|---|---|
| Prometheus | 192.168.192.130 | 9090 | Docker (network=host) |
| Grafana | 192.168.192.130 | 3000 | Docker (network=host) |
| node_exporter | 192.168.192.147 | 9100 | нативно (systemd) |
| postgres_exporter (опционально) | 192.168.192.147 | 9187 | нативно (systemd) |
| ComplexesMonitoringTCU-M | 192.168.192.147 | 9101–9104 | приложение (уже установлено) |

## Что и где устанавливаем

### На сервере мониторинга — 192.168.192.130

Все скрипты запускать от root, строго по порядку:

```bash
sudo ./00_prerequisites.sh              # утилиты, определение IP
sudo ./01_1_install_docker.sh           # установка Docker
sudo ./01_2_config_docker.sh            # зеркала Docker registry
sudo ./03_install_prometheus.sh         # Prometheus в Docker (скрейпит node_exporter на 147)
sudo ./04_install_grafana.sh            # Grafana в Docker (admin/admin, язык ru-RU)
sudo ./05_configure_grafana_datasource.sh  # datasource Prometheus в Grafana
sudo ./06_import_dashboard.sh           # дашборд Node Exporter Full (ID 1860)
sudo ./07_set_grafana_language.sh       # русский язык для пользователя admin
sudo ./08_add_app_metrics.sh            # job для приложения ComplexesMonitoringTCU-M (147:9101-9104)
```

### На сервере, который мониторим — 192.168.192.147

```bash
sudo ./00_prerequisites.sh              # утилиты, определение IP
sudo ./02_install_node_exporter.sh      # node_exporter (порт 9100, архитектура определяется автоматически)

# Опционально, для мониторинга PostgreSQL:
sudo ./postgres_exporter.sh             # postgres_exporter (порт 9187)
```

Само приложение ComplexesMonitoringTCU-M уже работает на 147 и отдаёт метрики
на портах 9101–9104 — его установка скриптами не требуется.

Для добавления job'а postgres_exporter в Prometheus выполните на сервере
мониторинга (130) аналогично `08_add_app_metrics.sh` (добавить job в
`/monitoring/prometheus/prometheus.yml` и выполнить `docker restart prometheus`):

```yaml
  - job_name: 'postgres_exporter'
    static_configs:
      - targets:
          - '192.168.192.147:9187'
```

## Файлы

- `common.sh` — общие функции (определение IP, ожидание сервиса, получение версии с GitHub API). Подключается скриптами автоматически, запускать не нужно.
- `collect_sh_files.ps1` — упаковка всех `.sh` в `sh_prgr.zip` (для переноса на Windows-машине).
- `cmd.txt` — рабочие заметки (scp, зеркала, конфигурация PostgreSQL).

## Метрики приложения ComplexesMonitoringTCU-M

Скрипт `08_add_app_metrics.sh` запускается **на сервере мониторинга (130)** и добавляет
в Prometheus job для приложения `ComplexesMonitoringTCU-M` на `192.168.192.147`,
порты `9101`–`9104`:

- идемпотентен: при повторном запуске не создаёт дубликат job'а;
- перед перезапуском проверяет конфиг через `promtool check config`;
- после перезапуска проверяет доступность endpoints и состояние targets.

Адреса и порты приложения задаются переменными в начале скрипта
(`APP_JOB_NAME`, `APP_HOST`, `APP_PORTS`).

## Перенос на сервер (с Windows-машины)

```powershell
.\collect_sh_files.ps1
scp sh_prgr.zip devuser@192.168.192.130:/tmp/   # на сервер мониторинга
scp sh_prgr.zip devuser@192.168.192.147:/tmp/   # на мониторируемый сервер
```

Далее на каждом сервере:

```bash
cd /tmp && unzip sh_prgr.zip && chmod +x *.sh
```

## Примечания

- Версии node_exporter/postgres_exporter берутся автоматически из GitHub API,
  при его недоступности используется запасная фиксированная версия.
- Пароль Grafana задается через `GF_SECURITY_ADMIN_PASSWORD` в `04_install_grafana.sh`.
- Язык интерфейса по умолчанию задается через `GF_USERS_DEFAULT_LANGUAGE` в `04_install_grafana.sh`.
- IP мониторируемого сервера задается переменной `MONITORED_IP` в `03_install_prometheus.sh`.
- Адрес и порты приложения задаются переменными `APP_HOST` и `APP_PORTS` в `08_add_app_metrics.sh`.
- Пароль postgres_exporter вшит в systemd-юнит; после установки выполните SQL-команды,
  которые скрипт выведет в консоль.
