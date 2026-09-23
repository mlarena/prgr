# prgr — автоматизация развёртывания стека мониторинга

Набор скриптов для установки стека мониторинга на Debian (x86_64 и ARM):

| Компонент | Порт | Способ установки |
|---|---|---|
| node_exporter | 9100 | нативно (systemd) |
| Prometheus | 9090 | Docker (network=host) |
| Grafana | 3000 | Docker (network=host) |
| postgres_exporter (опционально) | 9187 | нативно (systemd) |

## Порядок запуска

Все скрипты запускать от root, строго по порядку:

```bash
sudo ./00_prerequisites.sh              # утилиты, определение IP
sudo ./01_1_install_docker.sh           # установка Docker
sudo ./01_2_config_docker.sh            # зеркала Docker registry
sudo ./02_install_node_exporter.sh      # node_exporter (архитектура определяется автоматически)
sudo ./03_install_prometheus.sh         # Prometheus в Docker
sudo ./04_install_grafana.sh            # Grafana в Docker (admin/admin, язык ru-RU по умолчанию)
sudo ./05_configure_grafana_datasource.sh  # datasource Prometheus в Grafana
sudo ./06_import_dashboard.sh           # дашборд Node Exporter Full (ID 1860)
sudo ./07_set_grafana_language.sh       # русский язык для пользователя admin
```

Опционально, для мониторинга PostgreSQL:

```bash
sudo ./postgres_exporter.sh             # экспортер метрик PostgreSQL (порт 9187)
```

После установки добавить job в `/monitoring/prometheus/prometheus.yml` и перезапустить
Prometheus (`docker restart prometheus`):

```yaml
  - job_name: 'postgres_exporter'
    static_configs:
      - targets:
          - '192.168.192.137:9187'
          - '192.168.192.143:9187'
```

## Файлы

- `common.sh` — общие функции (определение IP, ожидание сервиса, получение версии с GitHub API). Подключается скриптами автоматически, запускать не нужно.
- `collect_sh_files.ps1` — упаковка всех `.sh` в `sh_prgr.zip` (для переноса на Windows-машине).
- `cmd.txt` — рабочие заметки (scp, зеркала, конфигурация PostgreSQL).

## Перенос на сервер (с Windows-машины)

```powershell
.\collect_sh_files.ps1
scp sh_prgr.zip devuser@<server_ip>:/tmp/
```

Далее на сервере:

```bash
cd /tmp && unzip sh_prgr.zip && chmod +x *.sh
```

## Примечания

- Версии node_exporter/postgres_exporter берутся автоматически из GitHub API,
  при его недоступности используется запасная фиксированная версия.
- Пароль Grafana задается через `GF_SECURITY_ADMIN_PASSWORD` в `04_install_grafana.sh`.
- Язык интерфейса по умолчанию задается через `GF_USERS_DEFAULT_LANGUAGE` в `04_install_grafana.sh`.
- Пароль postgres_exporter вшит в systemd-юнит; после установки выполните SQL-команды,
  которые скрипт выведет в консоль.
