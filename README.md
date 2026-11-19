# cake-shaper
Интерактивный установщик (install-shaper.sh). Он сам находит сетевые интерфейсы в системе, спрашивает у вас WAN, LAN и нужную скорость, создает рабочий скрипт шейпера, конфиг и регистрирует службу systemd.

### 💾 Скачать

```sh
wget -O install-shaper.sh https://raw.githubusercontent.com/atokarev-tech/cake-shaper/refs/heads/main/install-shaper.sh
```

или 

```sh
curl -o install-shaper.sh https://raw.githubusercontent.com/atokarev-tech/cake-shaper/refs/heads/main/install-shaper.sh
```



### ❎ Дать права на запуск

```sh
chmod +x install-shaper.sh
```



### 🚀 Запуск

```sh
sudo ./install-shaper.sh
```



### ⚙️ Управление

- `systemctl status cake-shaper` - проверить статус службы
- `systemctl stop cake-shaper` - временно отключить шейпер
- `systemctl start cake-shaper` - включить шейпер обратно
- `systemctl restart cake-shaper` - перезапустить (после правки `/etc/default/cake-shaper`)
- `/usr/local/sbin/cake-shaper.sh status` - посмотреть статистику пакетов CAKE
- `systemctl disable cake-shaper` - выключить шейпер



### 📖 Справка
CAKE в Linux — это современный алгоритм управления сетевым трафиком, предназначенный в основном для домашних роутеров и небольших сетей. Его цель — максимизировать пропускную способность и минимизировать задержки даже на медленных каналах связи.
На практике управление CAKE происходит через утилиту tc (traffic control) из пакета iproute2. Вы не запускаете «cake shaper» как отдельную программу, а настраиваете его как дисциплину очереди на сетевом интерфейсе.

Он объединяет в себе несколько функций:
- Шейпер (Shaper): Ограничивает скорость передачи данных, используя «дефицитный» алгоритм (deficit-mode), который помогает избегать резких всплесков трафика при старте.
- Управление очередями (AQM): Использует гибридный алгоритм COBALT (на основе Codel и BLUE) для борьбы с переполнением буфера (bufferbloat), снижая задержки.
- Справедливое распределение (FQ): Автоматически разделяет трафик на потоки и обеспечивает fairness (справедливость), чтобы одно приложение или устройство не «съедало» всю полосу.
