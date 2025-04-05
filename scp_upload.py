import paramiko
import os
import sys

def upload_to_fritzbox(local_file, ip="192.168.1.1", remote_path="/tmp", username="adam2", password=""):
    print(f" Verbinde zu {ip}...")
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    try:
        ssh.connect(ip, username=username, password=password, timeout=10)
        sftp = ssh.open_sftp()
        remote_file = os.path.join(remote_path, os.path.basename(local_file))
        print(f" Lade {local_file} hoch nach {remote_file}...")
        sftp.put(local_file, remote_file)
        sftp.close()
        ssh.close()
        print(" Upload erfolgreich!")
    except Exception as e:
        print(f" Fehler beim Hochladen: {e}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(" Nutzung: python scp_upload.py <lokale_datei>")
        sys.exit(1)

    local_file = sys.argv[1]
    upload_to_fritzbox(local_file)
