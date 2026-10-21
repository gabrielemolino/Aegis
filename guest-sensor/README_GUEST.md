# SentinelAI — Guest Telemetry Sensor (Ubuntu ARM64)

Questo modulo costituisce il sensore di telemetria guest di **SentinelAI** per macchine virtuali Linux/Ubuntu su architettura ARM64 (eseguite tramite UTM su Apple Silicon).

---

## 1. Architettura del Sensore

Il sensore (`sentinel_guest_sensor.py`) è progettato secondo i principi di **massima sicurezza e minimizzazione dell'impatto**:
- **Zero dipendenze esterne:** utilizza esclusivamente la standard library di Python 3 (`os`, `sys`, `time`, `json`, `socket`, `threading`).
- **Nessuna esecuzione di codice host:** il sensore raccoglie telemetria all'interno della VM e la emette come stream di oggetti JSON Lines (`.jsonl`).
- **Trattamento ostile per default (`isUntrustedData: true`):** qualsiasi stringa raccolta dal guest (linea di comando, payload file, injection) è marcata come dato passivo e non eseguibile.
- **Fail-Closed Heartbeat:** emette un segnale periodico di vitalità (`SENSOR_HEARTBEAT`). L'interruzione dell'heartbeat causa l'attivazione della regola deterministica `RULE-HEARTBEAT-000` (stato degradato / esito non verificabile).

---

## 2. Eventi Intercettati

| Tipologia Evento | Fonte | Descrizione |
| :--- | :--- | :--- |
| `PROCESS_SPAWN` | `/proc/[pid]/stat`, `cmdline` | Rileva la nascita di nuovi processi, PPID, nome comando e interpreti inattesi (`/bin/sh`, `/bin/bash`, `python`). |
| `FILE_IO` | Directory sensibili (`/tmp`, `/var/tmp`) | Modifiche, creazioni, burst di scrittura e rilevamento di estensioni malevole (`.locked`, `.crypto`, `.enc`). |
| `PERSISTENCE_WRITE` | `/etc/cron*`, `/etc/systemd` | Tentativi di installazione di script o servizi per mantenere la persistenza post-riavvio. |
| `NETWORK_ATTEMPT` | `/proc/net/tcp`, `/proc/net/udp` | Tentativi di connessione in uscita verso indirizzi IP non locali (in violazione dell'isolamento). |
| `SENSOR_HEARTBEAT` | Timer interno | Segnale di vitalità del sensore ogni 2.0s. |
| `LOG_MESSAGE` | Output / log monitorati | Messaggi informativi e cattura di tentativi di prompt injection. |

---

## 3. Installazione nella VM UTM (`SentinelAI-Ubuntu-Guest`)

### Metodo A: Copia rapida e Avvio Manuale
All'interno del terminale della VM Ubuntu:
```bash
# Scarica o incolla sentinel_guest_sensor.py
mkdir -p ~/sentinel-sensor
cd ~/sentinel-sensor

# Avvio del sensore con salvataggio su file JSONL
python3 sentinel_guest_sensor.py --output /tmp/sentinel-telemetry.jsonl --verbose
```

### Metodo B: Installazione come Servizio di Sistema (`systemd`)
Per mantenere il sensore sempre attivo come servizio di background nella VM:
```bash
sudo ./setup_guest.sh
sudo systemctl enable --now sentinel-sensor
```
Verifica stato del servizio:
```bash
sudo systemctl status sentinel-sensor
```

---

## 4. Modalità di Simulazione Controllata (Senza Malware Reale)

Il sensore include simulazioni sintetiche innocue per testare e dimostrare le regole di rilevamento senza ricorrere a campioni pericolosi:

| Flag | Descrizione Simulazione | Regola Host Attivata |
| :--- | :--- | :--- |
| `--simulate clean` | Ciclo di vita pulito, processo lecito, nessun allarme | `RULE-SAFE-001` (Non Rilevato) |
| `--simulate burst` | 15 scritture veloci in `/tmp` | `RULE-IO-014` (Sospetto, soglia burst) |
| `--simulate child_proc` | Processo genitore che avvia `/bin/sh` inatteso | `RULE-PROC-005` (Sospetto, conferma utente) |
| `--simulate network` | Tentativo di connessione TCP verso IP esterno | `RULE-NET-003` (Critico, arresto VM) |
| `--simulate persistence` | Scrittura su file in `/etc/cron.d/` | `RULE-PERSIST-002` (Critico, arresto VM) |
| `--simulate ransomware` | Modifica multipla con estensione `.locked` | `RULE-CRYPTO-009` (Critico, arresto VM) |
| `--simulate tamper` | Iniezione di prompt ostile nei log | `RULE-INJECT-001` (Dato Puro isolato) |
| `--simulate all` | Catena completa di tutti gli scenari | Tutte le regole verificate |

Esempio di generazione file di telemetria dimostrativo:
```bash
python3 sentinel_guest_sensor.py --simulate all --output /tmp/guest_telemetry_demo.jsonl
```

---

## 5. Importazione della Telemetria in SentinelAI (Host macOS)

1. Genera il file `.jsonl` nella VM.
2. Esporta il file sull'host macOS (ad es. copiando il testo o tramite file di log esportato).
3. Nell'applicazione **SentinelAI**:
   - Apri la schermata **Analisi e Contenimento**.
   - Seleziona **"Importa Telemetria Guest (.jsonl)"**.
   - Il motore deterministico (`RuleEngineService`) convaliderà ogni evento, calcolerà le regole attivate e produrrà la classificazione ufficiale con livello di confidenza e le azioni di contenimento raccomandate.
