#!/bin/bash

echo "=== МОНИТОРИНГ УСТАНОВКИ PROMETHEUS ==="
echo "Запускайте в отдельном терминале"
echo "Обновляется каждые 5 секунд"
echo "======================================"

while true; do
    clear
    echo "Время: $(date)"
    echo "======================================"
    
    # 1. Проверка процессов
    echo "1. ПРОЦЕССЫ:"
    echo "--------------------------------------"
    ps aux | grep -E "(docker|prometheus|03_install)" | grep -v grep || echo "   Не найдены"
    
    # 2. Проверка Docker
    echo -e "\n2. DOCKER:"
    echo "--------------------------------------"
    echo "Контейнеры:"
    docker ps -a 2>/dev/null | grep prometheus || echo "   Контейнер Prometheus не найден"
    
    echo -e "\nОбразы:"
    docker images 2>/dev/null | grep prometheus || echo "   Образ Prometheus не найден"
    
    # 3. Сеть
    echo -e "\n3. СЕТЕВАЯ АКТИВНОСТЬ:"
    echo "--------------------------------------"
    ss -tunap 2>/dev/null | grep -E "(docker|3000|9090|9100)" | head -5 || echo "   Нет сетевой активности"
    
    # 4. Диск
    echo -e "\n4. ДИСКОВОЕ ПРОСТРАНСТВО DOCKER:"
    echo "--------------------------------------"
    docker system df 2>/dev/null || echo "   Docker не доступен"
    
    # 5. Логи (последние 3 строки)
    echo -e "\n5. ПОСЛЕДНИЕ ЛОГИ DOCKER:"
    echo "--------------------------------------"
    journalctl -u docker -n 3 --no-pager 2>/dev/null || echo "   Логи недоступны"
    
    echo -e "\n======================================"
    echo "Для выхода: Ctrl+C"
    echo "Следующее обновление через 5 секунд..."
    sleep 5
done
