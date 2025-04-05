#!/bin/bash

# Variablen
ROUTER_IP="192.168.1.1"  # IP-Adresse des Routers
USERNAME="root"           # SSH-Benutzername
PASSWORD="your_password"  # SSH-Passwort
FIRMWARE_PATH="./firmware/openwrt-24.10.0-ipq40xx-generic-avm_fritzbox-7530-squashfs-sysupgrade.bin"
REMOTE_PATH="/tmp/firmware.bin"  # Zielpfad auf dem Router
PYTHON_SCP_SCRIPT="./scripts/scp_upload.py"  # Pfad zum SCP-Upload-Skript

# Überprüfen, ob Python 3 installiert ist
if ! command -v python3 &> /dev/null
then
    echo "Python 3 ist nicht installiert. Installieren Sie es und versuchen Sie es erneut."
    exit 1
fi

# Überprüfen, ob das Python-Skript existiert
if [ ! -f $PYTHON_SCP_SCRIPT ]; then
    echo "Fehler: SCP Upload Python-Skript nicht gefunden!"
    exit 1
fi

# SCP-Upload der Firmware
echo "Übertrage die Firmware auf den Router..."
python3 $PYTHON_SCP_SCRIPT $ROUTER_IP $USERNAME $PASSWORD $FIRMWARE_PATH $REMOTE_PATH
if [ $? -ne 0 ]; then
    echo "Fehler: Firmware konnte nicht auf den Router übertragen werden."
    exit 1
fi

echo "Firmware erfolgreich übertragen. Fortfahren mit dem Flashen..."

# Flashen der Firmware (Beispiel)
ssh root@$ROUTER_IP "sysupgrade -v $REMOTE_PATH"
if [ $? -ne 0 ]; then
    echo "Fehler: Flash-Vorgang gescheitert."
    exit 1
fi

echo "Der Flash-Vorgang wurde erfolgreich abgeschlossen."

