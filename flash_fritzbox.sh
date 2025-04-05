#!/bin/bash

# Variablen
ROUTER_IP="192.168.178.1"  # Ursprüngliche IP-Adresse der FRITZ!Box im Recovery-Modus
NEW_IP="192.168.1.2"       # Neue IP-Adresse für den Router
FIRMWARE_PATH="./firmware/openwrt-24.10.0-ipq40xx-generic-avm_fritzbox-7530-squashfs-sysupgrade.bin"
U_BOOT_PATH="./uboot/uboot-fritz7530.bin"
EVA_PATH="./eva/eva-fritz7530-recovery.img"
TFTP_DIR="/tmp"
PYTHON_SCRIPT="./scripts/eva_ramboot.py"  # Der Pfad zum Python-Skript

# Vorbereitungen
echo "Starte den Flash-Vorgang für die FRITZ!Box 7530..."
echo "Stellen Sie sicher, dass der Router mit dem PC über LAN verbunden ist und Ihre IP-Adresse auf 192.168.178.x gesetzt ist."

# Verbindung zum Router prüfen (dann Recovery-Modus)
ping -c 4 $ROUTER_IP
if [ $? -ne 0 ]; then
    echo "Fehler: Router nicht erreichbar. Überprüfen Sie die Verbindung und IP-Adresse."
    exit 1
fi

# Wechsel der IP-Adresse des Routers auf $NEW_IP per SSH
echo "Ändere die IP-Adresse des Routers auf $NEW_IP..."
ssh root@$ROUTER_IP "uci set network.lan.ipaddr=$NEW_IP && uci commit network && /etc/init.d/network restart"
if [ $? -ne 0 ]; then
    echo "Fehler: IP-Adresse konnte nicht geändert werden."
    exit 1
fi

# Neue IP-Adresse überprüfen
ping -c 4 $NEW_IP
if [ $? -ne 0 ]; then
    echo "Fehler: Router nach der IP-Änderung nicht erreichbar. Überprüfen Sie die Verbindung."
    exit 1
fi

# Aufruf des Python-Skripts, um das EVA-Image zu übertragen
echo "Lade das EVA-Image auf den Router..."
python3 $PYTHON_SCRIPT $NEW_IP $EVA_PATH --offset 0x88000000
if [ $? -ne 0 ]; then
    echo "Fehler: EVA-Image konnte nicht auf den Router übertragen werden."
    exit 1
fi

# TFTP-Verbindung für den U-Boot-Upload
echo "Lade den U-Boot Bootloader auf den Router..."
tftp $NEW_IP -c put $U_BOOT_PATH $TFTP_DIR/uboot.bin
if [ $? -ne 0 ]; then
    echo "Fehler: U-Boot konnte nicht auf den Router übertragen werden."
    exit 1
fi

# Firmware-Upload
echo "Übertrage die OpenWrt-Firmware auf den Router..."
scp $FIRMWARE_PATH root@$NEW_IP:$TFTP_DIR/firmware.bin
if [ $? -ne 0 ]; then
    echo "Fehler: Firmware konnte nicht auf den Router übertragen werden."
    exit 1
fi

# Flashen der Firmware
echo "Starte den Flash-Vorgang auf der FRITZ!Box 7530..."
ssh root@$NEW_IP "sysupgrade -v $TFTP_DIR/firmware.bin"
if [ $? -ne 0 ]; then
    echo "Fehler: Flash-Vorgang gescheitert."
    exit 1
fi

# Überprüfen des Flash-Vorgangs
echo "Flash-Vorgang abgeschlossen. Der Router wird nun neu gestartet..."
sleep 10

ping -c 4 $NEW_IP
if [ $? -ne 0 ]; then
    echo "Fehler: Router nach dem Neustart nicht erreichbar. Versuchen Sie, den Router in den Recovery-Modus zu versetzen."
    exit 1
else
    echo "Der Router ist nach dem Flashen erfolgreich erreichbar."
fi

echo "Der Flash-Vorgang wurde erfolgreich abgeschlossen. OpenWrt ist nun auf Ihrer FRITZ!Box 7530 installiert."

# Schritt 2: sysupgrade-Datei hochladen
echo "========================================"
echo " Schritt 2: sysupgrade nach FritzBox laden"
echo "========================================"
python3 scp_upload.py openwrt-24.10.0-ipq40xx-generic-avm_fritzbox-7530-squashfs-sysupgrade.bin

# Warte nach dem RAM-Boot 192.168.178.70
echo "========================================"
echo " Warte auf die IP 192.168.178.70 nach dem RAM-Boot..."
echo "========================================"
wait_for_ip 192.168.178.70 60

# Schritt 3: Flash-Vorgang starten
echo "========================================"
echo " Schritt 3: Flash-Vorgang starten"
echo "========================================"
python3 fritzflash.py \
  --image uboot-fritz7530.bin \
  --initramfs openwrt-24.10.0-ipq40xx-generic-avm_fritzbox-7530-initramfs-uImage \
  --sysupgrade openwrt-24.10.0-ipq40xx-generic-avm_fritzbox-7530-squashfs-sysupgrade.bin
