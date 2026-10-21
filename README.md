# SentinelAI

> **Applicazione macOS nativa con interfaccia grafica per analisi sicura, rilevamento comportamentale e contenimento in sandbox.**

[![macOS Apple Silicon](https://img.shields.io/badge/Platform-macOS%20Apple%20Silicon-blue.svg)](https://developer.apple.com/)
[![Swift 6.1](https://img.shields.io/badge/Swift-6.1-orange.svg)](https://swift.org)
[![SwiftUI](https://img.shields.io/badge/UI-SwiftUI%20Native-teal.svg)](https://developer.apple.com/xcode/swiftui/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Status: v0.1 Prototype](https://img.shields.io/badge/Release-v0.1%20Baseline-cyan.svg)](#roadmap-per-release)

---

## 1. Obiettivo del Progetto

SentinelAI aiuta l'utente a verificare file o programmi scaricati da Internet all'interno di un ambiente di analisi isolato controllato (macchina virtuale UTM su Apple Silicon).

Combina controlli di sicurezza tradizionali, preflight rigoroso per l'isolamento host, telemetria comportamentale in ambiente guest usa-e-getta, contenimento automatico e un LLM locale opzionale per la spiegazione guidata degli eventi.

> **Avvertenza di Sicurezza & Limiti Noti:**  
> SentinelAI è un **prototipo tecnico di ricerca e portfolio ingegneristico**, non un prodotto commerciale o un sostituto dei sistemi nativi di macOS (XProtect, Gatekeeper, MRT, Firewall). La priorità è ridurre la superficie d'attacco ed evitare diffusioni incontrollate, non garantire l'individuazione del 100% delle minacce o l'impossibilità assoluta di evasione da hypervisor.

---

## 2. Principi Non Negoziabili

1. **La sicurezza opera senza LLM:** Il motore deterministico di regole e il controller host intervengono autonomamente anche se l'LLM è offline, lento o soggetto a prompt injection.
2. **Nessun privilegio shell per l'LLM:** L'LLM analizza e spiega eventi; non possiede accesso a shell interattive e non esegue comandi arbitrari.
3. **Isolamento Massimo di Default:** Niente rete, niente cartelle host condivise, niente sincronizzazione degli appunti e nessun dispositivo USB passthrough.
4. **Nessuna esecuzione implicita:** I file selezionati dall'utente vengono ispezionati staticamente sull'host calcolandone l'hash SHA-256 in modalità safe-read. Nessun file viene eseguito sul Mac host.
5. **Nessun malware reale nel repository:** Il codice, i test e i workflow CI impiegano esclusivamente fixture e simulazioni innocue.
6. **Policy Fail-Closed:** Se un prerequisito essenziale o lo stato di isolamento della VM non sono verificabili con certezza, l'ambiente viene marcato come `Verifica manuale richiesta` e l'analisi viene **bloccata**.

---

## 3. Architettura Logica (v0.1)

```text
┌─────────────────────────────────────────────────────────────────┐
│                      Host macOS (Apple Silicon)                 │
│                                                                 │
│  ┌────────────────────────┐         ┌────────────────────────┐  │
│  │   SwiftUI Native App   │         │   Audit Logger Locale  │  │
│  │ • Dashboard Panoramica │         │ • Immutabile           │  │
│  │ • Onboarding & Preflight─────────▶ • Sanificato           │  │
│  │ • Selettore File Sicuro│         │ • Export JSON / Testo  │  │
│  └───────────┬────────────┘         └────────────────────────┘  │
│              │                                                  │
│              ▼                                                  │
│  ┌────────────────────────┐         ┌────────────────────────┐  │
│  │   SecurityEngine Host  │         │  SystemCheckService    │  │
│  │ • Calcolo SHA-256 puro │         │ • Apple Silicon arm64  │  │
│  │ • Regole deterministiche◀───────── • macOS 14+ compatibile│  │
│  │ • Controlli Preflight  │         │ • UTM.app detection    │  │
│  └───────────┬────────────┘         └────────────────────────┘  │
└──────────────┼──────────────────────────────────────────────────┘
               │ Nessuna condivisione cartelle / Nessuna rete / Fail-Closed
               ▼
┌─────────────────────────────────────────────────────────────────┐
│              UTM Isolated Sandbox (Guest Usa-e-getta)           │
│                                                                 │
│  • VM Designata: SentinelAI-Ubuntu-Guest                        │
│  • Ripristino automatico da Snapshot pulito                     │
│  • Telemetria guest e contenimento controllato dal controller   │
└─────────────────────────────────────────────────────────────────┘
```

---

## 4. Requisiti di Sistema

- **Piattaforma:** macOS 14 (Sonoma) o successivo su Apple Silicon (M1 / M2 / M3 / M4 / M5).
- **Toolchain:** Swift 6.0+ o Xcode 16+.
- **Sandbox Guest:** [UTM Virtual Machines per macOS](https://mac.getutm.app/).

---

## 5. Compilazione ed Esecuzione

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

## 6. Risultati della Suite di Test v0.1

Tutti i test unitari e di sicurezza sono eseguiti in locale e verificati:

```text
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
Executed 21 tests, with 0 failures in 0.216 seconds.
```

---

## 7. Roadmap per Release

| Milestone | Descrizione | Stato |
| :--- | :--- | :--- |
| **v0.1** | UI nativa SwiftUI, dashboard, navigazione, onboarding, preflight fail-closed, motore simulato, audit log. | **Completato** |
| **v0.2** | Gestione guidata UTM: wizard interattivo 5 passi, indurimento (rete, clipboard, cartelle, USB), query con watchdog timeout, policy bonifica snapshot ('clean-baseline'). | **Completato** |
| **v0.3** | Motore di regole deterministico completo con parser eventi e fixture arricchite. | Prossimo passo |
| **v0.4** | Controllo VM: controllo host limitato e verificato per avviare/fermare la sola VM autorizzata; test di errore e conferma dell'esito. | Pianificato |
| **v0.5** | Sensore guest su Ubuntu ARM64 per telemetria di base (processi, file, rete). | Pianificato |
| **v0.6** | Integrazione LLM locale con Ollama (spiegazione semantica con schema JSON validato). | Pianificato |
| **v0.7** | Beta pubblica, test end-to-end con simulazioni innocue e packaging macOS. | Pianificato |

---

## 8. Licenza

Rilasciato sotto licenza [MIT](LICENSE).
