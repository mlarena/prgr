#!/bin/bash

# Скрипт для автоматической установки русского языка в Grafana через API
# IP адрес сервера (определяется автоматически или из файла)

# Получение IP из файла или автоматическое определение
if [ -f /tmp/server_ip.txt ]; then
    SERVER_IP=$(cat /tmp/server_ip.txt)
else
    SERVER_IP=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -n1)
fi

# Если IP не определился, используем localhost
if [ -z "$SERVER_IP" ]; then
    SERVER_IP="localhost"
fi

GRAFANA_URL="http://${SERVER_IP}:3000"
GRAFANA_USER="admin"
GRAFANA_PASS="admin"

echo "========================================="
echo "Настройка русского языка в Grafana"
echo "Grafana URL: ${GRAFANA_URL}"
echo "========================================="

# Функция для ожидания готовности Grafana
wait_for_grafana() {
    echo "Ожидание запуска Grafana..."
    MAX_RETRIES=30
    RETRY_COUNT=0
    while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
        if curl -s "${GRAFANA_URL}/api/health" > /dev/null 2>&1; then
            echo "Grafana готова к работе"
            return 0
        fi
        echo "Ожидание Grafana... ($RETRY_COUNT/$MAX_RETRIES)"
        sleep 2
        RETRY_COUNT=$((RETRY_COUNT+1))
    done
    echo "Ошибка: Grafana не запустилась"
    return 1
}

# Функция для получения cookies и токена аутентификации
grafana_login() {
    # Получаем cookies и токен
    local login_response=$(curl -s -c /tmp/grafana_cookies.txt \
        -X POST "${GRAFANA_URL}/login" \
        -H "Content-Type: application/json" \
        -d "{\"user\":\"${GRAFANA_USER}\",\"password\":\"${GRAFANA_PASS}\"}")
    
    # Получаем токен из cookies
    if grep -q "grafana_session" /tmp/grafana_cookies.txt 2>/dev/null; then
        echo "Аутентификация успешна"
        return 0
    else
        echo "Ошибка аутентификации"
        return 1
    fi
}

# Функция для установки языка через API пользователя
set_user_language() {
    local language=$1
    
    echo "Установка языка пользователя ${GRAFANA_USER} на ${language}..."
    
    # Получаем ID пользователя
    local user_id=$(curl -s -b /tmp/grafana_cookies.txt \
        "${GRAFANA_URL}/api/user" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)
    
    if [ -z "$user_id" ]; then
        echo "Не удалось получить ID пользователя"
        return 1
    fi
    
    # Устанавливаем язык через API пользовательских настроек
    curl -s -b /tmp/grafana_cookies.txt \
        -X PUT "${GRAFANA_URL}/api/user/preferences" \
        -H "Content-Type: application/json" \
        -d "{\"locale\":\"${language}\"}" > /dev/null
    
    if [ $? -eq 0 ]; then
        echo "Язык пользователя установлен на ${language}"
        return 0
    else
        echo "Ошибка установки языка пользователя"
        return 1
    fi
}

# Функция для установки языка по умолчанию для всех пользователей (требует прав admin)
set_default_language() {
    local language=$1
    
    echo "Установка языка по умолчанию для всех пользователей на ${language}..."
    
    # Устанавливаем глобальные настройки через API
    curl -s -b /tmp/grafana_cookies.txt \
        -X PUT "${GRAFANA_URL}/api/org/preferences" \
        -H "Content-Type: application/json" \
        -d "{\"locale\":\"${language}\"}" > /dev/null
    
    if [ $? -eq 0 ]; then
        echo "Язык по умолчанию установлен на ${language}"
        return 0
    else
        echo "Ошибка установки языка по умолчанию"
        return 1
    fi
}

# Функция для проверки текущего языка
check_current_language() {
    echo "Проверка текущих настроек языка..."
    
    # Проверяем настройки пользователя
    local user_prefs=$(curl -s -b /tmp/grafana_cookies.txt \
        "${GRAFANA_URL}/api/user/preferences")
    
    local user_locale=$(echo "$user_prefs" | grep -o '"locale":"[^"]*"' | cut -d'"' -f4)
    
    if [ -n "$user_locale" ]; then
        echo "Текущий язык пользователя: ${user_locale}"
    else
        echo "Текущий язык пользователя: не установлен (используется английский)"
    fi
}

# Основной процесс
echo "Шаг 1: Ожидание готовности Grafana"
wait_for_grafana || exit 1

echo ""
echo "Шаг 2: Аутентификация в Grafana"
grafana_login || exit 1

echo ""
echo "Шаг 3: Проверка текущего языка"
check_current_language

echo ""
echo "Шаг 4: Установка русского языка"
# Код языка для русского - 'ru' или 'ru-RU'
# Grafana использует формат IETF language tag (например, ru-RU, en-US, zh-CN) [citation:4][citation:7]
set_user_language "ru-RU"

if [ $? -eq 0 ]; then
    echo ""
    echo "========================================="
    echo "Русский язык успешно установлен!"
    echo "========================================="
    echo "Для применения изменений обновите страницу Grafana (F5 или Ctrl+R)"
    echo "Grafana доступна по адресу: ${GRAFANA_URL}"
    echo "Логин: ${GRAFANA_USER}"
    echo "Пароль: ${GRAFANA_PASS}"
else
    echo ""
    echo "========================================="
    echo "Не удалось установить русский язык"
    echo "Попробуйте установить вручную:"
    echo "1. Войдите в Grafana: ${GRAFANA_URL}"
    echo "2. Нажмите на аватар в правом нижнем углу"
    echo "3. Выберите Profile"
    echo "4. В разделе Preferences выберите Russian"
    echo "5. Нажмите Update"
    echo "========================================="
fi

# Очистка временных файлов
rm -f /tmp/grafana_cookies.txt