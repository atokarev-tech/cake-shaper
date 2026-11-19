#!/bin/bash
set -e

if [ "$EUID" -ne 0 ]; then
  echo "Ошибка: запустите скрипт от имени root (sudo bash $0)"
  exit 1
fi

echo "=== Установка CAKE Traffic Shaper ==="
echo ""
echo "Найденные сетевые интерфейсы:"
echo "---------------------------------------------------"
ip -o -4 addr show | awk '{print "  " $2 " -> " $4}'
echo "---------------------------------------------------"
echo "(Все доступные физические интерфейсы: $(ls /sys/class/net | grep -vE '^(lo|ifb|tun|tap|wg|docker|veth|br)' | tr '\n' ' '))"
echo ""

# Запрос WAN интерфейса
while true; do
  read -rp "Введите имя WAN-интерфейса (интернет, например enp3s0): " WAN_IF
  if [ -d "/sys/class/net/$WAN_IF" ]; then
    break
  else
    echo "Интерфейс '$WAN_IF' не найден. Попробуйте еще раз."
  fi
done

# Запрос LAN интерфейса
while true; do
  read -rp "Введите имя LAN-интерфейса (локальная сеть, например enp4s0): " LAN_IF
  if [ -d "/sys/class/net/$LAN_IF" ]; then
    break
  else
    echo "Интерфейс '$LAN_IF' не найден. Попробуйте еще раз."
  fi
done

# Запрос скорости
read -rp "Скорость ОТДАЧИ (Upload) в Мбит/с [по умолчанию 48]: " UP_SPEED
UP_SPEED=${UP_SPEED:-48}

read -rp "Скорость ЗАГРУЗКИ (Download) в Мбит/с [по умолчанию 48]: " DOWN_SPEED
DOWN_SPEED=${DOWN_SPEED:-48}

echo ""
echo "Создаю конфигурацию и скрипты..."

# 1. Файл конфигурации (чтобы потом легко менять скорость без переустановки)
cat << CONF > /etc/default/cake-shaper
WAN_IF="$WAN_IF"
LAN_IF="$LAN_IF"
UP_SPEED="${UP_SPEED}mbit"
DOWN_SPEED="${DOWN_SPEED}mbit"
CONF

# 2. Основной исполняемый скрипт управления
cat << 'SCRIPT' > /usr/local/sbin/cake-shaper.sh
#!/bin/bash
source /etc/default/cake-shaper

start() {
    echo "Запуск CAKE шейпера на $WAN_IF (Up: $UP_SPEED, Down: $DOWN_SPEED)..."

    # Очистка старых правил на случай повторного запуска
    stop >/dev/null 2>&1 || true

    # 1. Настройка исходящего трафика (Upload) на WAN
    tc qdisc replace dev "$WAN_IF" root cake bandwidth "$UP_SPEED" diffserv4 nat dual-srchost

    # 2. Подготовка IFB и перенаправление входящего трафика (Download)
    modprobe ifb numifbs=1
    ip link set dev ifb0 up
    tc qdisc replace dev "$WAN_IF" handle ffff: ingress
    tc filter replace dev "$WAN_IF" parent ffff: matchall action mirred egress redirect dev ifb0
    tc qdisc replace dev ifb0 root cake bandwidth "$DOWN_SPEED" diffserv4 nat dual-dsthost ingress

    # 3. Увеличение кольцевых буферов сетевых карт
    ethtool -G "$WAN_IF" rx 4096 tx 4096 2>/dev/null || true
    ethtool -G "$LAN_IF" rx 4096 tx 4096 2>/dev/null || true

    echo "Шейпер успешно запущен."
}

stop() {
    echo "Отключение шейпера..."
    tc qdisc del dev "$WAN_IF" root 2>/dev/null || true
    tc qdisc del dev "$WAN_IF" ingress 2>/dev/null || true
    tc qdisc del dev ifb0 root 2>/dev/null || true
    ip link set dev ifb0 down 2>/dev/null || true
    echo "Шейпер отключен."
}

status() {
    echo "=== Статус $WAN_IF (Upload) ==="
    tc -s qdisc show dev "$WAN_IF"
    echo ""
    echo "=== Статус ifb0 (Download) ==="
    tc -s qdisc show dev ifb0 2>/dev/null || echo "ifb0 не активен"
}

case "$1" in
    start)   start ;;
    stop)    stop ;;
    restart) stop; start ;;
    status)  status ;;
    *)       echo "Использование: $0 {start|stop|restart|status}"; exit 1 ;;
esac
SCRIPT

chmod +x /usr/local/sbin/cake-shaper.sh

# 3. Служба systemd
cat << 'SERVICE' > /etc/systemd/system/cake-shaper.service
[Unit]
Description=CAKE Traffic Shaper & Ring Buffer Tuning
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/sbin/cake-shaper.sh start
ExecStop=/usr/local/sbin/cake-shaper.sh stop
ExecReload=/usr/local/sbin/cake-shaper.sh restart

[Install]
WantedBy=multi-user.target
SERVICE

# Активация службы
systemctl daemon-reload
systemctl enable cake-shaper.service
systemctl start cake-shaper.service

echo ""
echo "=== Установка завершена! ==="
echo "Служба добавлена в автозагрузку и уже запущена."
echo ""
echo "Полезные команды для управления:"
echo "  systemctl status cake-shaper   - проверить статус службы"
echo "  systemctl stop cake-shaper     - временно отключить шейпер"
echo "  systemctl start cake-shaper    - включить шейпер обратно"
echo "  systemctl restart cake-shaper  - перезапустить (после правки /etc/default/cake-shaper)"
echo "  /usr/local/sbin/cake-shaper.sh status - посмотреть статистику пакетов CAKE"
