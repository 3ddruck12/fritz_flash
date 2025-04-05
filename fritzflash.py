#!/usr/bin/env python3
import sys
import time
import os
import subprocess
import paramiko
from ftplib import FTP
from pathlib import Path

# Funktion zum Warten auf eine IP-Adresse
def wait_for_ip(ip, timeout=60):
    print(f"Warten auf {ip}...")
    for _ in range(timeout):
        response = os.system(f"ping -c 1 {ip}")
        if response == 0:
            print(f"{ip} erreichbar!")
            return True
        time.sleep(1)
    print(f"{ip} nicht erreichbar, Zeitüberschreitung!")
    return False

# Funktion zum Hochladen von Dateien über SFTP
def upload_file_sftp(local_path, remote_path, ip="192.168.178.70", username="root", password=""):
    try:
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(ip, username=username, password=password)
        sftp = ssh.open_sftp()
        sftp.put(local_path, remote_path)
        sftp.close()
        ssh.close()
        print(f"Datei {local_path} erfolgreich auf {ip} hochgeladen.")
    except Exception as e:
        print(f"Fehler beim Hochladen über SFTP: {e}")

# Funktion für den Flash-Vorgang über SSH
def flash_device(image_file, initramfs_file, sysupgrade_file, ip="192.168.178.70"):
    print(f"Starte Flash-Vorgang auf {ip}...")
    try:
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(ip, username="root", password="")

        # Hochladen der U-Boot- und Initramfs-Dateien
        upload_file_sftp(image_file, '/tmp/uboot-fritz7530.bin', ip)
        upload_file_sftp(initramfs_file, '/tmp/openwrt-24.10.0-ipq40xx-generic-avm_fritzbox-7530-initramfs-uImage', ip)
        upload_file_sftp(sysupgrade_file, '/tmp/openwrt-24.10.0-ipq40xx-generic-avm_fritzbox-7530-squashfs-sysupgrade.bin', ip)

        # Flash-Befehl ausführen
        command = f"sysupgrade -n /tmp/{os.path.basename(sysupgrade_file)}"
        stdin, stdout, stderr = ssh.exec_command(command)
        print(stdout.read().decode())
        print(stderr.read().decode())

        ssh.close()
        print("Flashen abgeschlossen!")
    except Exception as e:
        print(f"Fehler beim Flashen: {e}")

# Funktion zur FTP-Verbindung (Alternative zum SFTP)
def upload_via_ftp(ip, file_path):
    try:
        ftp = FTP(ip)
        ftp.login('adam2', 'adam2')
        with open(file_path, 'rb') as file:
            ftp.storbinary(f"STOR /tmp/{os.path.basename(file_path)}", file)
        ftp.quit()
        print(f"Datei {file_path} erfolgreich hochgeladen!")
    except Exception as e:
        print(f"Fehler beim Hochladen via FTP: {e}")

# Hauptfunktion zum Starten des Flash-Vorgangs
def main():
    if len(sys.argv) != 4:
        print("Usage: python3 fritzflash.py <image_file> <initramfs_file> <sysupgrade_file>")
        sys.exit(1)

    image_file = sys.argv[1]
    initramfs_file = sys.argv[2]
    sysupgrade_file = sys.argv[3]

    # 1. Warten auf die IP der FritzBox im RAM-Boot (192.168.178.2)
    if not wait_for_ip("192.168.178.2", timeout=60):
        print("FritzBox konnte nicht im RAM-Boot-Modus gefunden werden.")
        sys.exit(1)

    # 2. Warten auf die finale IP der FritzBox nach dem RAM-Boot (192.168.178.70)
    if not wait_for_ip("192.168.178.70", timeout=60):
        print("FritzBox konnte nach dem RAM-Boot nicht erreicht werden.")
        sys.exit(1)

    # 3. Flash-Vorgang auf die FritzBox starten
    flash_device(image_file, initramfs_file, sysupgrade_file)

if __name__ == "__main__":
    main()
