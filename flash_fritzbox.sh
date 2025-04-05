#!/bin/bash

set -e
cd "$(dirname "$0")"

# Funktionen
wait_for_ip() {
  local ip=$1
  local timeout=${2:-60}
  echo -n " Warte auf Gerät bei $ip "
  for ((i=0; i<$timeout; i++)); do
    if ping -c 1 -W 1 "$ip" >/dev/null 2>&1; then
      echo "  gefunden!"
      return 0
    fi
    echo -n "."
    sleep 1
  done
  echo "  Zeitüberschreitung bei $ip"
  return 1
}

# Schritt 1: RAM-Boot vorbereiten
echo "========================================"
echo " Schritt 1: RAM-Boot vorbereiten..."
echo "========================================"
read -p "Drücke Enter zum Starten des RAM-Boots..."
python3 eva_ramboot.py --offset 0x85000000 192.168.178.1 uboot-fritz7530.bin

# Warte auf U-Boot (192.168.1.1)
echo "========================================"
echo " Warte auf U-Boot IP 192.168.1.1..."
echo "========================================"
wait_for_ip 192.168.1.1 60

# Schritt 2: sysupgrade-Datei hochladen
echo "========================================"
echo " Schritt 2: sysupgrade nach FritzBox laden"
echo "========================================"
python3 scp_upload.py openwrt-24.10.0-ipq40xx-generic-avm_fritzbox-7530-squashfs-sysupgrade.bin

# Schritt 3: Flash-Vorgang starten
echo "========================================"
echo " Schritt 3: Flash-Vorgang starten"
echo "========================================"
python3 fritzflash.py \
  --image uboot-fritz7530.bin \
  --initramfs openwrt-24.10.0-ipq40xx-generic-avm_fritzbox-7530-initramfs-uImage \
  --sysupgrade openwrt-24.10.0-ipq40xx-generic-avm_fritzbox-7530-squashfs-sysupgrade.bin
