# Aegis

> **Native macOS graphical application for secure file inspection, behavioral telemetry detection, and automated sandbox containment on Apple Silicon.**  
> *Deterministic Rule Engine, Disposable UTM Virtualization, and Local LLM (qwen2.5-coder:3b via Ollama).*

[![Aegis CI](https://github.com/gabrielemolino/Aegis/actions/workflows/ci.yml/badge.svg)](https://github.com/gabrielemolino/Aegis/actions/workflows/ci.yml)
[![macOS Apple Silicon](https://img.shields.io/badge/Platform-macOS%20Apple%20Silicon-blue.svg)](https://developer.apple.com/)
[![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![SwiftUI](https://img.shields.io/badge/UI-SwiftUI%20Native-teal.svg)](https://developer.apple.com/xcode/swiftui/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Status: v0.7 Beta](https://img.shields.io/badge/Release-v0.7%20Beta%20Release-brightgreen.svg)](#9-release-roadmap)
[![Tests: 50 Swift + 6 Python](https://img.shields.io/badge/Tests-56%20Passing-success.svg)](#7-test-suite-results-v07-end-to-end--localization)

---

## 📌 Table of Contents
- [⚠️ Limitation of Liability / Legal Disclaimer](#️-limitation-of-liability--legal-disclaimer)
- [1. Project Overview](#1-project-overview)
- [2. Non-Negotiable Principles](#2-non-negotiable-principles)
- [3. Architecture Overview (v0.7)](#3-architecture-overview-v07)
- [4. Repository Structure](#4-repository-structure)
- [5. System Requirements](#5-system-requirements)
- [6. Building and Running](#6-building-and-running)
- [7. Test Suite Results (v0.7 End-to-End & Localization)](#7-test-suite-results-v07-end-to-end--localization)
- [8. Packaging & Standalone Distribution (.app, .dmg, .zip)](#8-packaging--standalone-distribution-macos-apple-silicon)
- [9. Release Roadmap](#9-release-roadmap)
- [10. Security & Contribution Resources](#10-security--contribution-resources)
- [11. License](#11-license)

---

## ⚠️ Limitation of Liability / Legal Disclaimer

> **ENGLISH:**  
> **The author and developers of Aegis expressly disclaim any and all liability and responsibility for any use made of this software, or for any direct, indirect, incidental, special, or consequential damages, loss of data, system malfunctions, or security incidents arising from analyzing, handling, or interacting with potentially malicious, unknown, or hazardous files.**  
> The user assumes sole and exclusive responsibility for their actions, for ensuring the strict isolation of their hardware and network infrastructure, and for compliance with all applicable cybersecurity and computer fraud laws. This software is provided strictly **"AS IS"** for educational, defensive research, security auditing, and controlled sandbox experimentation purposes.
>
> **ITALIANO:**  
> **L'autore e gli sviluppatori di Aegis declinano ogni responsabilità per l'uso che l'utente fa del software e per qualsiasi conseguenza, danno diretto o indiretto, perdita di dati o malfunzionamento del sistema derivante dall'analisi, gestione o manipolazione di file potenzialmente malevoli o sconosciuti.**  
> L'utente è l'unico ed esclusivo responsabile delle proprie azioni, dell'isolamento della propria infrastruttura e della conformità alle leggi vigenti in materia di sicurezza informatica. Il software è fornito "COSÌ COM'È" a scopo di ricerca difensiva, audit e analisi controllata.

---

## 1. Project Overview

**Aegis** empowers security researchers and macOS users to verify suspicious files and downloads in a strictly isolated, disposable environment (UTM virtualization on Apple Silicon).

It pairs traditional deterministic security rules with strict host preflight checks, ephemeral guest runtime telemetry, automated containment controls, and an optional local LLM (`qwen2.5-coder:3b` via Ollama) for semantic threat triage, MITRE ATT&CK mapping, and plain-language explanation of anomalous events.

The application includes **native bilingual support (Italian & English)**, configurable upon first launch in the Onboarding modal and changeable at any time in the Settings screen.

---

## 2. Non-Negotiable Principles

1. **Safety Operates Without LLM:** Deterministic rule evaluation and host containment execute independently. The core defense system functions fully even if the LLM is offline, high-latency, or targeted by prompt injection.
2. **Zero Shell Privileges for the LLM:** The LLM is strictly an analytical observer. It never possesses interactive shell access, privileged sockets, or operating system execution capabilities.
3. **Maximum Default Isolation:** No network connectivity, no shared host folders, no shared clipboard, and no USB passthrough.
4. **No Implicit Host Execution:** Target files undergo static cryptographic inspection (SHA-256) on the macOS host via safe read-only operations. No sample is ever executed on the host Mac.
5. **Zero Real Malware in Repository:** Repository code, unit tests, and continuous integration pipelines use exclusively synthetic benign fixtures and controlled simulations.
6. **Fail-Closed Policy:** If any security prerequisite or VM isolation state cannot be deterministically verified, the environment is marked as `Manual Verification Required` and analysis is **blocked**.

---

## 3. Architecture Overview (v0.7)

```text
┌─────────────────────────────────────────────────────────────────┐
│                      Host macOS (Apple Silicon)                 │
│                                                                 │
│  ┌────────────────────────┐         ┌────────────────────────┐  │
│  │   Aegis SwiftUI App    │         │   Local Audit Logger   │  │
│  │ • Overview Dashboard   │         │ • Append-Only          │  │
│  │ • Bilingual Onboarding ├─────────▶ • Sanitized            │  │
│  │ • Safe File Selector   │         │ • JSON / Text Export   │  │
│  │ • Legal Disclaimer Card│         └────────────────────────┘  │
│  └───────────┬────────────┘                                     │
│              │                                                  │
│              ▼                                                  │
│  ┌────────────────────────┐         ┌────────────────────────┐  │
│  │   SecurityEngine Host  │         │ Local LLM (Ollama)     │  │
│  │ • Pure SHA-256 Hashing │         │ • Model:               │  │
│  │ • Deterministic Rules  ◀───────────  qwen2.5-coder:3b     │  │
│  │ • Preflight Verification         │ • Strict JSON Schema   │  │
│  │ • Automated VM Contain ──┐       │ • MITRE ATT&CK Mapping │  │
│  └────────────────────────┘ │       │ • Anti-Prompt Injection│  │
│                             │       │ • Anti-Hallucination   │  │
│                             │       └────────────────────────┘  │
└─────────────────────────────┼───────────────────────────────────┘
                              │ Host Controller (No shared folders / No LAN / Fail-Closed)
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│              UTM Isolated Sandbox (Disposable Guest)            │
│                                                                 │
│  • Authorized VM: SentinelAI-Ubuntu-Guest                       │
│  • Guest Agent: sentinel_guest_sensor.py (Python 3 stdlib)     │
│  • Ingestion: Unidirectional JSONL Telemetry Stream             │
│  • Automatic Rollback from Clean Snapshot ('clean-baseline')    │
└─────────────────────────────────────────────────────────────────┘
```

---

## 4. Repository Structure

```text
Aegis/
├── .github/
│   ├── workflows/ci.yml           # GitHub Actions CI (macOS-14 Apple Silicon, Xcode 16)
│   └── ISSUE_TEMPLATE/            # Standard bug report, feature request & config
├── Sources/SentinelAI/            # Native macOS Application Sources (SwiftUI & Swift 6)
│   ├── App/                       # Entry point, AppState, and application lifecycle
│   ├── Models/                    # Telemetry event schemas, reports, and MITRE models
│   ├── Services/
│   │   ├── LocalizationManager.swift # Reactive bilingual manager (IT / EN)
│   │   ├── SecurityEngine.swift   # Deterministic rules & containment orchestrator
│   │   ├── VMHostController.swift # UTM AppleScript controller & watchdog probe
│   │   ├── LocalLLMService.swift  # Local LLM service (Ollama qwen2.5-coder:3b)
│   │   ├── TelemetryIngestionService.swift # Safe JSONL stream parser & validator
│   │   ├── SystemCheckService.swift # Host environment & architecture sanity checks
│   │   └── AuditLogger.swift      # Sanitized immutable log exporter (JSON / text)
│   └── Views/                     # Native SwiftUI reactive interface
│       ├── Navigation/SidebarView.swift
│       └── Screens/               # Overview, UTM Manager, Rule Workbench, LLM, Settings
├── Tests/SentinelAITests/         # 50 Swift Unit, Integration & End-to-End Tests
├── guest-sensor/                  # Python 3 telemetry agent for Ubuntu ARM64 Guest
│   ├── sentinel_guest_sensor.py   # Process spawn, burst I/O & egress network monitor
│   └── test_sensor.py             # 6 Telemetry validation unit tests
├── scripts/
│   └── package_macos.sh           # Standalone packaging script (.app, .dmg, .zip)
├── CONTRIBUTING.md                # Contributor guidelines & zero-malware policy
├── SECURITY.md                    # Security policy, responsible disclosure & disclaimer
├── THREAT_MODEL.md                # Formal STRIDE threat model & isolation boundaries
├── LICENSE                        # MIT License
└── Package.swift                  # Swift Package Manager manifest (Swift 6.0+)
```

---

## 5. System Requirements

- **Operating System:** macOS 14 (Sonoma) or newer on **Apple Silicon** (M1 / M2 / M3 / M4 / M5).
- **Toolchain:** Swift 6.0+ or Xcode 16.0+.
- **Guest Sandbox:** [UTM Virtual Machines for macOS](https://mac.getutm.app/) (Free / Open-Source).
- **Local LLM Analyst (Optional):** [Ollama](https://ollama.com/) with model `qwen2.5-coder:3b`.
  ```bash
  # Install Ollama via Homebrew
  brew install ollama
  brew services start ollama
  
  # Pull the lightweight model optimized for 8GB / 16GB Apple Silicon
  ollama pull qwen2.5-coder:3b
  ```

---

## 6. Building and Running

```bash
# 1. Clone the repository
git clone https://github.com/gabrielemolino/Aegis.git
cd Aegis

# 2. Build in debug mode
swift build

# 3. Run all unit and integration tests (50 tests)
swift test

# 4. Launch the native SwiftUI application
swift run SentinelAI
```

---

## 7. Test Suite Results (v0.7 End-to-End & Localization)

All 50 Swift tests and 6 Python guest sensor tests run locally and in GitHub Actions CI with **0 failures**:

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

## 8. Packaging & Standalone Distribution (macOS Apple Silicon)

Aegis includes an automated script to compile release binaries and generate an ad-hoc signed `.app` bundle, a compressed ZIP archive, and a mountable DMG disk image:

```bash
# Package Aegis.app, ZIP archive, and DMG disk image
chmod +x scripts/package_macos.sh
./scripts/package_macos.sh
```

Distribution artifacts generated in `dist/`:
- `dist/Aegis.app` — Standalone native macOS app bundle with `Info.plist` (macOS 14.0+) and ad-hoc arm64 code signature.
- `dist/Aegis-v0.7.0-macOS-arm64.zip` — Compressed archive for direct distribution.
- `dist/Aegis-v0.7.0-macOS-arm64.dmg` — Mountable macOS disk image for drag-and-drop installation into `/Applications`.

---

## 9. Release Roadmap

| Milestone | Description | Status |
| :--- | :--- | :---: |
| **v0.1** | Native SwiftUI UI, dashboard, navigation, onboarding, fail-closed preflight, simulated engine, audit log. | **Completed** |
| **v0.2** | UTM guided management: 5-step wizard, hardening (network, clipboard, folders, USB), query timeout, rollback policy ('clean-baseline'). | **Completed** |
| **v0.3** | Complete deterministic rule engine with versioned catalog, event parser, 6 synthetic datasets, interactive workbench, and evidence linking. | **Completed** |
| **v0.4** | VM host controller: authorized VM whitelist, unauthorized target rejection, real shutdown verification, post-containment rollback enforcement. | **Completed** |
| **v0.5** | Python 3 guest telemetry sensor on Ubuntu ARM64 (processes, burst I/O, network egress, heartbeat), safe JSONL ingestion, non-simulated analysis. | **Completed** |
| **v0.6** | Local LLM integration with Ollama (`qwen2.5-coder:3b`), semantic triage, MITRE ATT&CK mapping, rigid JSON schema validation, anti-hallucination evidence guard, fail-closed fallback. | **Completed** |
| **v0.7** | Rebranded to **Aegis**, reactive bilingual localization (Italian / English in onboarding & settings), legal disclaimer & limitation of liability clause, end-to-end test suite (50 tests), and standalone macOS `.app` / `.dmg` packaging. | **Completed** |

---

## 10. Security & Contribution Resources

- [THREAT_MODEL.md](THREAT_MODEL.md) — Detailed STRIDE threat analysis, trust boundaries, considered attack vectors, and mitigations.
- [SECURITY.md](SECURITY.md) — Security policy, responsible vulnerability disclosure process, and limitation of liability.
- [CONTRIBUTING.md](CONTRIBUTING.md) — Contribution guidelines, bilingual dictionary conventions, and strict zero-malware policy.

---

## 11. License

Released under the [MIT License](LICENSE).  
Copyright (c) 2026 Aegis Contributors.
