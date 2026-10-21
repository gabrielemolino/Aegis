#!/usr/bin/env bash
# SentinelAI — Guest Setup & Installer Script (Ubuntu ARM64)
# Eseguibile all'interno della VM Ubuntu (SentinelAI-Ubuntu-Guest)

set -euo pipefail

echo "=========================================================="
echo " SentinelAI — Installatore Sensore Guest (Ubuntu ARM64)  "
echo "=========================================================="

# 1. Verifica Python 3
if ! command -v python3 &>/dev/null; then
    echo "[!] Python 3 non trovato. Installazione in corso..."
    sudo apt-get update && sudo apt-get install -y python3
else
    echo "[+] Python 3 rilevato: $(python3 --version)"
fi

# 2. Creazione directory /opt/sentinel-sensor
INSTALL_DIR="/opt/sentinel-sensor"
echo "[*] Preparazione directory: ${INSTALL_DIR}..."
sudo mkdir -p "${INSTALL_DIR}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
sudo cp "${SCRIPT_DIR}/sentinel_guest_sensor.py" "${INSTALL_DIR}/"
sudo chmod +x "${INSTALL_DIR}/sentinel_guest_sensor.py"

# 3. Installazione unit systemd opzionale
if [ -d "/etc/systemd/system" ]; then
    echo "[*] Installazione servizio systemd (sentinel-sensor.service)..."
    sudo cp "${SCRIPT_DIR}/sentinel-sensor.service" "/etc/systemd/system/"
    sudo systemctl daemon-reload
    echo "[+] Servizio installato. Per abilitarlo:"
    echo "    sudo systemctl enable --now sentinel-sensor"
    echo "    Per visualizzare i log: journalctl -u sentinel-sensor -f"
fi

# 4. Verifica di funzionamento
echo "[*] Esecuzione test di autodiagnostica..."
python3 "${INSTALL_DIR}/sentinel_guest_sensor.py" --simulate clean > /dev/null

echo "=========================================================="
echo "[✓] Installazione completata con successo!"
echo "Telemetria generata in: /var/log/sentinel-telemetry.jsonl"
echo "=========================================================="
