#!/bin/bash

# Variablen
ROUTER_IP="192.168.1.1"  # IP-Adresse des Routers
FTP_USER="adam2"          # FTP-Benutzername
FTP_PASS="adam2"          # FTP-Passwort
FIRMWARE_PATH="./firmware/openwrt-24.10.0-ipq40xx-generic-avm_fritzbox-7530-squashfs-sysupgrade.bin"
EVA_PATH="./eva/eva-fritz7530-recovery.img"
U_BOOT_PATH="./uboot/uboot-fritz7530.bin"
REMOTE_PATH="/tmp/firmware.bin"  # Zielpfad auf dem Router

# Vorbereitungen
echo "Starte den Flash-Vorgang für die FRITZ!Box 7530..."
echo "Stellen Sie sicher, dass der Router im Recovery-Modus ist."

# Verbindung zum Router prüfen (Recovery-Modus)
ping -c 4 $ROUTER_IP
if [ $? -ne 0 ]; then
    echo "Fehler: Router nicht erreichbar. Überprüfen Sie die Verbindung und IP-Adresse."
    exit 1
fi

# Überprüfen, ob die benötigten Dateien existieren
if [ ! -f "$EVA_PATH" ]; then
    echo "Fehler: EVA-Image wurde nicht gefunden!"
    exit 1
fi

if [ ! -f "$U_BOOT_PATH" ]; then
    echo "Fehler: U-Boot-Datei wurde nicht gefunden!"
    exit 1
fi

if [ ! -f "$FIRMWARE_PATH" ]; then
    echo "Fehler: Firmware-Datei wurde nicht gefunden!"
    exit 1
fi

# Verbindung zu FTP herstellen und EVA-Image übertragen
echo "Übertrage das EVA-Image auf den Router..."
ftp -inv $ROUTER_IP <<EOF
user $FTP_USER $FTP_PASS
binary
put $EVA_PATH 0x88000000
quit
EOF

# Übertragen der U-Boot-Datei
echo "Übertrage die U-Boot-Datei auf den Router..."
ftp -inv $ROUTER_IP <<EOF
user $FTP_USER $FTP_PASS
binary
put $U_BOOT_PATH 0x80000000
quit
EOF

# Übertragen der Firmware
echo "Übertrage die OpenWrt-Firmware auf den Router..."
ftp -inv $ROUTER_IP <<EOF
user $FTP_USER $FTP_PASS
binary
put $FIRMWARE_PATH $REMOTE_PATH
quit
EOF

# Flashen der Firmware über SSH
echo "Starte den Flash-Vorgang auf der FRITZ!Box 7530..."
ssh root@$ROUTER_IP "sysupgrade -v $REMOTE_PATH"
if [ $? -ne 0 ]; then
    echo "Fehler: Flash-Vorgang gescheitert."
    exit 1
fi

echo "Der Flash-Vorgang wurde erfolgreich abgeschlossen. Router wird jetzt neu gestartet."


echo "Der Flash-Vorgang wurde erfolgreich abgeschlossen. Router wird jetzt neu gestartet."

