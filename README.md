# Aegis

> **Applicazione macOS nativa con interfaccia grafica per analisi sicura, rilevamento comportamentale e contenimento in sandbox.**  
> *Bilingual (Italiano / English) Sandbox Security Defense for macOS Apple Silicon.*

[![Aegis CI](https://github.com/gabrielemolino/Aegis/actions/workflows/ci.yml/badge.svg)](https://github.com/gabrielemolino/Aegis/actions/workflows/ci.yml)
[![macOS Apple Silicon](https://img.shields.io/badge/Platform-macOS%20Apple%20Silicon-blue.svg)](https://developer.apple.com/)
[![Swift 6.1](https://img.shields.io/badge/Swift-6.1-orange.svg)](https://swift.org)
[![SwiftUI](https://img.shields.io/badge/UI-SwiftUI%20Native-teal.svg)](https://developer.apple.com/xcode/swiftui/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Status: v0.7 Beta](https://img.shields.io/badge/Release-v0.7%20Beta%20Release-brightgreen.svg)](#8-roadmap-per-release)
[![Tests: 50 Swift + 6 Python](https://img.shields.io/badge/Tests-56%20Passing-success.svg)](#6-risultati-della-suite-di-test-v07-end-to-end--bilinguismo)

---

## 📌 Indice dei Contenuti
- [Clausola di Esonero di Responsabilità / Legal Disclaimer](#-clausola-di-esonero-di-responsabilità--legal-disclaimer)
- [1. Obiettivo del Progetto](#1-obiettivo-del-progetto)
- [2. Principi Non Negoziabili](#2-principi-non-negoziabili)
- [3. Architettura Logica (v0.7)](#3-architettura-logica-v07)
- [4. Struttura del Repository](#4-struttura-del-repository)
- [5. Requisiti di Sistema](#5-requisiti-di-sistema)
- [6. Compilazione ed Esecuzione](#6-compilazione-ed-esecuzione)
- [7. Risultati della Suite di Test](#7-risultati-della-suite-di-test-v07-end-to-end--bilinguismo)
- [8. Packaging & Distribuzione (.app, .dmg, .zip)](#8-packaging--distribuzione-standalone-macos-apple-silicon)
- [9. Roadmap per Release](#9-roadmap-per-release)
- [10. Risorse di Sicurezza e Collaborazione](#10-risorse-di-sicurezza-e-collaborazione)

---

## ⚠️ Clausola di Esonero di Responsabilità / Legal Disclaimer

> **ITALIANO:**  
> **L'autore e gli sviluppatori di Aegis declinano ogni responsabilità per l'uso che l'utente fa del software e per qualsiasi conseguenza, danno diretto o indiretto, perdita di dati o malfunzionamento del sistema che possa derivare dall'analisi, gestione o manipolazione di file potenzialmente malevoli o sconosciuti.**  
> L'utente è l'unico ed esclusivo responsabile delle proprie azioni, dell'isolamento della propria infrastruttura e della conformità alle leggi vigenti in materia di sicurezza informatica. Il software è fornito "COSÌ COM'È" a scopo di ricerca difensiva, audit e analisi controllata.
>
> **ENGLISH:**  
> **The author and developers of Aegis disclaim all liability and responsibility for any use made of this software by the user, or for any consequences, direct or indirect damages, data loss, or system issues arising from analyzing, handling, or interacting with potentially malicious or unknown files.**  
> The user assumes sole responsibility for their actions, environment isolation, and compliance with applicable cybersecurity regulations. The software is provided "AS IS" for defensive research, auditing, and controlled sandbox analysis.

---

## 1. Obiettivo del Progetto

Aegis aiuta l'utente a verificare file o programmi scaricati da Internet all'interno di un ambiente di analisi isolato controllato (macchina virtuale UTM su Apple Silicon).

Combina controlli di sicurezza tradizionali, preflight rigoroso per l'isolamento host, telemetria comportamentale in ambiente guest usa-e-getta, contenimento automatico e un LLM locale opzionale (`qwen2.5-coder:3b` via Ollama) per la spiegazione guidata degli eventi e il mapping MITRE ATT&CK.

L'applicazione include **supporto bilingue nativo (Italiano / Inglese)** configurabile durante l'onboarding di installazione e modificabile in qualsiasi momento nella scheda Impostazioni.

---

## 2. Principi Non Negoziabili

1. **La sicurezza opera senza LLM:** Il motore deterministico di regole e il controller host intervengono autonomamente anche se l'LLM è offline, lento o soggetto a prompt injection.
2. **Nessun privilegio shell per l'LLM:** L'LLM analizza e spiega eventi; non possiede accesso a shell interattive e non esegue comandi arbitrari.
3. **Isolamento Massimo di Default:** Niente rete, niente cartelle host condivise, niente sincronizzazione degli appunti e nessun dispositivo USB passthrough.
4. **Nessuna esecuzione implicita:** I file selezionati dall'utente vengono ispezionati staticamente sull'host calcolandone l'hash SHA-256 in modalità safe-read. Nessun file viene eseguito sul Mac host.
5. **Nessun malware reale nel repository:** Il codice, i test e i workflow CI impiegano esclusivamente fixture e simulazioni innocue.
6. **Policy Fail-Closed:** Se un prerequisito essenziale o lo stato di isolamento della VM non sono verificabili con certezza, l'ambiente viene marcato come `Verifica manuale richiesta` e l'analisi viene **bloccata**.

---

## 3. Architettura Logica (v0.7)

```text
┌─────────────────────────────────────────────────────────────────┐
│                      Host macOS (Apple Silicon)                 │
│                                                                 │
│  ┌────────────────────────┐         ┌────────────────────────┐  │
│  │   Aegis SwiftUI App    │         │   Audit Logger Locale  │  │
│  │ • Dashboard Panoramica │         │ • Immutabile           │  │
│  │ • Onboarding Bilingue  ├─────────▶ • Sanificato           │  │
│  │ • Selettore File Sicuro│         │ • Export JSON / Testo  │  │
│  │ • Esonero Responsabilit│         └────────────────────────┘  │
│  └───────────┬────────────┘                                     │
│              │                                                  │
│              ▼                                                  │
│  ┌────────────────────────┐         ┌────────────────────────┐  │
│  │   SecurityEngine Host  │         │ Local LLM (Ollama)     │  │
│  │ • Calcolo SHA-256 puro │         │ • Modello:             │  │
│  │ • Regole deterministiche◀──────────  qwen2.5-coder:3b     │  │
│  │ • Controlli Preflight  │         │ • Schema JSON rigido   │  │
│  │ • Contenimento VM      │         │ • Mapping MITRE ATT&CK │  │
│  └───────────┬────────────┘         │ • Anti-Prompt Injection│  │
│              │                      │ • Anti-Allucinazione   │  │
│              │                      └────────────────────────┘  │
└──────────────┼──────────────────────────────────────────────────┘
               │ Nessuna condivisione cartelle / Nessuna rete / Fail-Closed
               ▼
┌─────────────────────────────────────────────────────────────────┐
│              UTM Isolated Sandbox (Guest Usa-e-getta)           │
│                                                                 │
│  • VM Designata: SentinelAI-Ubuntu-Guest                        │
│  • Sensore Telemetrico: sentinel_guest_sensor.py (Python 3)     │
│  • Ingestione: Stream JSONL unidirezionale                      │
│  • Ripristino automatico da Snapshot pulito                     │
└─────────────────────────────────────────────────────────────────┘
```

---

## 4. Struttura del Repository

```text
Aegis/
├── .github/
│   ├── workflows/ci.yml           # GitHub Actions CI (macOS-14 Apple Silicon)
│   └── ISSUE_TEMPLATE/            # Template ufficiali per bug report e feature request
├── Sources/SentinelAI/            # Sorgenti dell'applicazione macOS nativa
│   ├── App/                       # Entry point, AppState e ciclo di vita SwiftUI
│   ├── Models/                    # Schemi di telemetria, report e MITRE ATT&CK
│   ├── Services/
│   │   ├── LocalizationManager.swift # Gestore bilinguismo reattivo (IT/EN)
│   │   ├── SecurityEngine.swift   # Motore deterministico e policy di contenimento
│   │   ├── VMHostController.swift # Controller host per VM UTM e query watchdog
│   │   ├── LocalLLMService.swift  # Servizio LLM locale (Ollama qwen2.5-coder:3b)
│   │   ├── TelemetryIngestionService.swift # Ingestione e convalida stream JSONL
│   │   ├── SystemCheckService.swift # Sanity check ambiente e architettura host
│   │   └── AuditLogger.swift      # Audit logging sanificato ed esportazione
│   └── Views/                     # Componenti visuali SwiftUI
│       ├── Navigation/SidebarView.swift
│       └── Screens/               # Panoramica, UTM Wizard, Banco Regole, LLM, Impostazioni
├── Tests/SentinelAITests/         # 50 Test Swift unitari, di sicurezza ed E2E
├── guest-sensor/                  # Sensore di telemetria per Ubuntu Guest (Python 3)
│   ├── sentinel_guest_sensor.py   # Rilevamento processi, burst I/O e rete
│   └── test_sensor.py             # 6 Test di validazione telemetrica
├── scripts/
│   └── package_macos.sh           # Script di build release e packaging (.app, .dmg, .zip)
├── CONTRIBUTING.md                # Linee guida per collaboratori e policy zero-malware
├── SECURITY.md                    # Politica di sicurezza, disclosure ed esonero legale
├── THREAT_MODEL.md                # Modello di minaccia formale STRIDE e confini di sicurezza
├── LICENSE                        # Licenza MIT
└── Package.swift                  # Manifest di compilazione Swift Package Manager
```

---

## 5. Requisiti di Sistema

- **Piattaforma:** macOS 14 (Sonoma) o successivo su Apple Silicon (M1 / M2 / M3 / M4 / M5).
- **Toolchain:** Swift 6.0+ o Xcode 16+.
- **Sandbox Guest:** [UTM Virtual Machines per macOS](https://mac.getutm.app/).
- **Analista LLM Locale (Opzionale v0.6):** [Ollama](https://ollama.com/) con modello `qwen2.5-coder:3b`.
  ```bash
  # Installazione Ollama tramite Homebrew
  brew install ollama
  
  # Download ed esecuzione del modello ottimizzato per Apple Silicon 8GB
  ollama pull qwen2.5-coder:3b
  ollama run qwen2.5-coder:3b
  ```

---

## 6. Compilazione ed Esecuzione

```bash
# Spostati nella cartella del progetto
cd SentinelAI

# Compila l'applicazione con Swift Package Manager
swift build

# Esegui la suite completa di test unitari e di policy
swift test

# Avvia l'applicazione nativa
swift run SentinelAI
```

---

## 7. Risultati della Suite di Test v0.7 (End-to-End & Bilinguismo)

Tutti i 50 test unitari, deterministici, di sicurezza, di integrazione LLM e di localizzazione bilingue sono eseguiti in locale e verificati:

```text
✔ Test "Bilinguismo Reattivo (Italiano & Inglese): Commutazione lingua istantanea e coerenza dizionario" passed
✔ Test "Clausola Esonero di Responsabilità: Presenza e completezza del testo legale in entrambe le lingue" passed
✔ Test "E2E Pipeline Completa: Da ispezione statica ad arresto VM, triage LLM ed export log" passed
✔ Test "Validazione Schema JSON Rigoroso: convalida corretta dei campi strutturati" passed
✔ Test "Anti-Allucinazione: scarta categoricamente ID evento inesistenti o inventati dall'LLM" passed
✔ Test "Allowlist Azioni Raccomandate: azioni non autorizzate ripiegano in sicurezza su LOG_AND_MONITOR" passed
✔ Test "Resilienza Prompt Difensivo: la telemetria untrusted è confinata e marcata come dato passivo" passed
✔ Test "Fail-Safe su JSON Non Conforme: scarta risposte troncate o corrotte senza crash" passed
✔ Test "Simulatore Mock qwen2.5-coder:3b: genera report coerenti con gli scenari comportamentali" passed
✔ Test "Integrazione SecurityEngine: allegamento semantico dell'LLM all'analisi finale" passed
✔ Test "Verifica completezza delle 4 classificazioni ammesse" passed
✔ Test "Verifica sanity check baseline" passed
✔ Test "Verifica checklist di isolamento e conteggio controlli pendenti" passed
✔ Test "Verifica superamento Preflight quando tutte le condizioni rigorose sono soddisfatte" passed
✔ Test "Verifica Fail-Closed: preflight fallisce se la VM non è in stato verificata" passed
✔ Test "Verifica sanificazione stringhe contro log injection" passed
✔ Test "Verifica esportazione in formato JSON valido" passed
✔ Test "Verifica rilevamento architettura host" passed
✔ Test "Verifica rilevamento installazione UTM" passed
✔ Test "Verifica calcolo crittografico sicuro SHA-256 senza esecuzione" passed
✔ Test "Verifica Fail-Closed: preflight fallisce se nessun file è selezionato" passed
✔ Test "Verifica Fail-Closed: preflight fallisce se lo snapshot pulito non è confermato" passed
✔ Test "Verifica report simulato conforme alle specifiche e con disclaimer espliciti" passed
✔ Test "Verifica compatibilità versione macOS" passed
✔ Test "Verifica ispezione ambiente iniziale" passed
✔ Test "Verifica esportazione in formato testo" passed
✔ Test "Validazione nome VM: accetta identificatori conformi" passed
✔ Test "Validazione nome VM: rifiuta injection, caratteri speciali e traversal" passed
✔ Test "Hardening Checklist: richiede tassativamente tutti i 5 criteri di isolamento" passed
✔ Test "Policy Bonifica: la sospensione conserva lo stato compromesso e non è bonifica" passed
✔ Test "Interrogazione stato VM: timeout di sicurezza non bloccante" passed
✔ Test "Catalogo regole: integrità e versionamento del catalogo" passed
✔ Test "Regola Clean: ciclo di vita standard viene classificato come Non Rilevato" passed
✔ Test "Regola I/O Burst (RULE-IO-014): rileva modifiche frequenti in /tmp con soglia configurabile" passed
✔ Test "Regola Processi Figli (RULE-PROC-005): intercetta interpreti inattesi e associa ID evento" passed
✔ Test "Regola Persistenza Critica (RULE-PERSIST-002): attiva raccomandazione arresto VM" passed
✔ Test "Regola Heartbeat (RULE-HEARTBEAT-000): assenza di telemetria porta a stato degradato (Fail-Closed)" passed
✔ Test "Regola Anti-Tamper (RULE-INJECT-001): prompt injection trattata rigorosamente come dato passivo" passed
✔ Test "Autorizzazione: rifiuta categoricamente comandi verso VM non autorizzate" passed
✔ Test "Autorizzazione: accetta la sola VM autorizzata configurata" passed
✔ Test "Controllo Host: avvio simulato con conferma dello stato in esecuzione" passed
✔ Test "Contenimento: arresto confermato e registrazione evento di sicurezza" passed
✔ Test "Policy Bonifica Post-Arresto: obbligo di rollback prima di nuove analisi" passed
✔ Test "Verifica parsing conforme di stream JSONL dal sensore guest" passed
✔ Test "Resilienza: righe corrotte o incomplete vengono scartate senza crash (Fail-Safe)" passed
✔ Test "Rilevamento Burst /tmp: attiva RULE-IO-014 e classificazione Sospetta" passed
✔ Test "Rilevamento Violazione Rete: attiva RULE-NET-003 e classificazione Rilevato (Critico)" passed
✔ Test "Rilevamento Persistenza Non Autorizzata: attiva RULE-PERSIST-002" passed
✔ Test "Anti-Tamper nei log: prompt injection trattata rigorosamente come dato passivo" passed
✔ Test "Analisi completa con SecurityEngine produce report reale (isSimulatedDemo == false)" passed
Executed 50 Swift tests with 0 failures in 0.267 seconds.
Executed 6 Python sensor validation tests with 0 failures in 2.548 seconds.
```

---

## 8. Packaging & Distribuzione Standalone (macOS Apple Silicon)

Aegis v0.7 include uno script automatizzato per compilare e impacchettare l'applicazione in un bundle `.app` nativo firmato ad-hoc, oltre alla creazione di un archivio ZIP e di un'immagine disco DMG:

```bash
# Compilazione ed esportazione bundle Aegis.app, ZIP e DMG
chmod +x scripts/package_macos.sh
./scripts/package_macos.sh
```

I file generati nella cartella `dist/`:
- `dist/Aegis.app` — Bundle applicativo macOS nativo con `Info.plist` (Sonoma 14.0+) e firma ad-hoc arm64.
- `dist/Aegis-v0.7.0-macOS-arm64.zip` — Archivio compresso per distribuzione diretta.
- `dist/Aegis-v0.7.0-macOS-arm64.dmg` — Immagine disco macOS con mount rapido per installazione in `/Applications`.

---

## 9. Roadmap per Release

| Milestone | Descrizione | Stato |
| :--- | :--- | :--- |
| **v0.1** | UI nativa SwiftUI, dashboard, navigazione, onboarding, preflight fail-closed, motore simulato, audit log. | **Completato** |
| **v0.2** | Gestione guidata UTM: wizard interattivo 5 passi, indurimento (rete, clipboard, cartelle, USB), query con watchdog timeout, policy bonifica snapshot ('clean-baseline'). | **Completato** |
| **v0.3** | Motore di regole deterministico completo con catalogo versionato, parser eventi, 6 dataset fixture sintetiche, banco di prova interattivo ed evidenze con ID evento. | **Completato** |
| **v0.4** | Controllo VM: controller host per la sola VM autorizzata, divieto VM estranee, conferma reale dell'arresto (zero falsi successi), obbligo rollback post-contenimento. | **Completato** |
| **v0.5** | Sensore guest Python 3 su Ubuntu ARM64 (processi, file, rete, heartbeat), ingestione sicura JSONL, analisi reale non simulata. | **Completato** |
| **v0.6** | Integrazione LLM locale con Ollama (`qwen2.5-coder:3b`), spiegazione semantica, mapping MITRE ATT&CK, validazione JSON rigida, anti-allucinazione evidenze, fail-closed fallback. | **Completato** |
| **v0.7** | Rebranding ad **Aegis**, localizzazione bilingue reattiva (IT/EN all'onboarding e nelle impostazioni), clausola esplicita di non responsabilità, test suite end-to-end (50 test) e packaging standalone `.app` / `.dmg` per macOS. | **Completato** |

---

## 10. Risorse di Sicurezza e Collaborazione

- [THREAT_MODEL.md](THREAT_MODEL.md) — Analisi dettagliata delle minacce STRIDE, vettori di attacco considerati e mitigazioni.
- [SECURITY.md](SECURITY.md) — Politica di sicurezza, disclosure responsabile e limitazione di responsabilità legale.
- [CONTRIBUTING.md](CONTRIBUTING.md) — Linee guida per contribuire, convenzioni sul bilinguismo e divieto assoluto di malware reale.

---

## 11. Licenza

Rilasciato sotto licenza [MIT](LICENSE).
Copyright (c) 2026 Aegis Contributors.


