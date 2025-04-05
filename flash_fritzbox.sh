import time
import os
import sys

# Funktion, um den Router zu prüfen (ping)
def check_router_reachability(ip="192.168.1.1", retries=5, delay=60):
    for attempt in range(retries):
        response = os.system(f"ping -c 1 {ip}")
        if response == 0:
            print(f"Router erreichbar beim Versuch {attempt + 1}")
            return True
        print(f"Versuch {attempt + 1}: Router nicht erreichbar, versuche es erneut...")
        time.sleep(delay)
    return False

# Initiale Überprüfung des Routers
ping_response = os.system("ping -c 1 192.168.1.1")

if ping_response != 0:
    print("Fehler: Router nicht erreichbar.")
    print("Bitte trenne den Netzstecker des Routers, warte etwa 10 Sekunden und stecke ihn dann wieder ein.")
    input("Drücke Enter, sobald der Router wieder mit Strom versorgt ist und die LED blinkt (im Recovery-Modus)...")

    # Überprüfe nach der Benutzereingabe erneut, ob der Router erreichbar ist
    print("Überprüfe jetzt erneut, ob der Router erreichbar ist...")
    if not check_router_reachability():
        print("Fehler: Router immer noch nicht erreichbar. Bitte überprüfe die Verbindung und den Wiederherstellungsmodus.")
        sys.exit(1)
    else:
        print("Router ist jetzt erreichbar. Der Flashvorgang wird fortgesetzt.")
else:
    print("Router ist bereits erreichbar. Der Flashvorgang wird fortgesetzt.")

# Hier den Flash-Vorgang einfügen (z.B. Befehl zum Flashen der Firmware)
# Beispiel: os.system("flash_befehl")

# Abschlussnachricht
print("\nDer Flashvorgang wurde erfolgreich abgeschlossen.")
print("Die FRITZ!Box 7530 ist nun geflasht und sollte im normalen Betrieb starten.")

