# cake-shaper
Интерактивный установщик (install-shaper.sh). Он сам находит сетевые интерфейсы в системе, спрашивает у вас WAN, LAN и нужную скорость, создает рабочий скрипт шейпера, конфиг и регистрирует службу systemd.

### Скачать

```sh
wget -O install-shaper.sh https://raw.githubusercontent.com/atokarev-tech/cake-shaper/refs/heads/main/install-shaper.sh
```

или 

```sh
curl -o install-shaper.sh https://raw.githubusercontent.com/atokarev-tech/cake-shaper/refs/heads/main/install-shaper.sh
```

### Дать права на запуск

```sh
chmod +x install-shaper.sh
```

### Запуск

```sh
sudo ./install-shaper.sh
```

### Управление

- `systemctl status cake-shaper` - проверить статус службы
- `systemctl stop cake-shaper` - временно отключить шейпер
- `systemctl start cake-shaper` - включить шейпер обратно
- `systemctl restart cake-shaper` - перезапустить (после правки `/etc/default/cake-shaper`)
- `/usr/local/sbin/cake-shaper.sh status` - посмотреть статистику пакетов CAKE
- `systemctl disable cake-shaper` - выключить шейпер
