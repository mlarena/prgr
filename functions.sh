#!/bin/bash

# Функции для автоматического определения IP адреса

get_server_ip() {
    # Пытаемся получить IP через различные методы
    
    # Метод 1: IP адрес основного интерфейса (обычно eth0, ens3, enp0s3)
    local ip=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -n1)
    
    # Метод 2: через hostname -I
    if [ -z "$ip" ]; then
        ip=$(hostname -I | awk '{print $1}')
    fi
    
    # Метод 3: через ip route
    if [ -z "$ip" ]; then
        ip=$(ip route get 1 | awk '{print $NF;exit}')
    fi
    
    # Метод 4: через curl к внешним сервисам (если есть интернет)
    if [ -z "$ip" ]; then
        if command -v curl &> /dev/null; then
            ip=$(curl -s ifconfig.me 2>/dev/null)
        fi
    fi
    
    # Если IP не определен, используем localhost
    if [ -z "$ip" ]; then
        ip="127.0.0.1"
        echo "ВНИМАНИЕ: Не удалось определить IP адрес. Используется localhost" >&2
    fi
    
    echo "$ip"
}

# Функция для получения всех IP адресов интерфейсов
get_all_ips() {
    ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1'
}

# Функция для выбора IP пользователем (если их несколько)
select_ip() {
    local ips=($(get_all_ips))
    local ip_count=${#ips[@]}
    
    if [ $ip_count -eq 0 ]; then
        echo "127.0.0.1"
    elif [ $ip_count -eq 1 ]; then
        echo "${ips[0]}"
    else
        echo "Обнаружено несколько IP адресов:" >&2
        for i in "${!ips[@]}"; do
            echo "$((i+1)). ${ips[$i]}" >&2
        done
        echo -n "Выберите IP для мониторинга (1-${ip_count}): " >&2
        read choice
        if [[ $choice =~ ^[0-9]+$ ]] && [ $choice -ge 1 ] && [ $choice -le $ip_count ]; then
            echo "${ips[$((choice-1))]}"
        else
            echo "${ips[0]}" >&2
        fi
    fi
}