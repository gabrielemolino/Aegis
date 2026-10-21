# Aegis — Threat Model & Security Architecture

**Versione:** 0.7 (Beta Release)  
**Target:** macOS su Apple Silicon (arm64)  
**Ambiente Isolato:** Virtualizzazione UTM (QEMU / Apple Virtualization Framework)  

---

## ⚠️ Clausola di Esonero di Responsabilità Legale (Non-Responsibility Disclaimer)

> **L'autore e gli sviluppatori di Aegis non sono in alcun caso responsabili per l'uso che l'utente fa del programma, né per eventuali danni diretti, indiretti, perdita di dati, malfunzionamenti o conseguenze derivanti dall'analisi di campioni software o file potenzialmente ostili.**  
> Il programma è concepito esclusivamente come strumento di ausilio all'analisi e audit difensivo. Qualsiasi manipolazione di file sconosciuti o potenzialmente dannosi avviene sotto la **piena ed esclusiva responsabilità dell'utente**, che deve verificare autonomamente la sicurezza e l'integrità del proprio ambiente hardware e software.

---

## 1. Obiettivo di Sicurezza e Postura di Difesa

Aegis è progettato per analizzare file e payload potenzialmente malevoli riducendo al minimo la superficie d'attacco per l'host macOS.

> **Assunzione Fondamentale:** Nessun sistema di isolamento software o hypervisor è teoricamente immune da escape o vulnerabilità 0-day. Aegis **non** promette protezione assoluta né sostituisce i controlli nativi di macOS (XProtect, Gatekeeper, MRT, Firewall). La sua priorità ingegneristica è il **contenimento deterministico**, la **separazione dei privilegi** e il principio **Fail-Closed**.

---

## 2. Principi di Architettura Non Negoziabili

1. **LLM disaccoppiato dall'azione diretta:**
   - L'LLM opera come analista e generatore di spiegazioni semantiche.
   - L'LLM **non riceve mai accesso a una shell interattiva, socket privilegiate o comandi di sistema**.
   - Le azioni di contenimento (es. arresto forzato della VM) sono definite in codice nativo Swift, controllate da allowlist rigorosa e attivate da un motore deterministico di regole, indipendentemente dallo stato o dalla latenza dell'LLM.
   - Protezione contro Prompt Injection: ogni output proveniente dal guest, da file o da log è trattato come **dato non attendibile** (data-only) e validato contro schemi rigidi prima di essere elaborato.

2. **Isolamento Rigoroso di Default (Sandboxing UTM):**
   - **Rete:** Disconnessa di default. Nessuna interfaccia bridged su LAN domestica o aziendale.
   - **Filesystem Condiviso:** Disattivato. Nessun volume host (es. Desktop, Downloads, Documenti) montato via WebDAV, VirtFS o 9p.
   - **Clipboard & Drag-and-Drop:** Disattivati per impedire transiti non intenzionali di payload.
   - **Dispositivi:** Nessun passthrough USB consentito.
   - **Usa-e-getta:** L'analisi viene condotta esclusivamente su cloni effimeri o snapshot puliti ripristinabili.

3. **Policy Fail-Closed (Preflight Bloccante):**
   - Se uno qualsiasi dei controlli di isolamento non può essere verificato in modo deterministico, il sistema **blocca l'avvio dell'analisi** e contrassegna l'ambiente come `Verifica manuale richiesta` o `Non sicura`.
   - L'applicazione **non dichiara mai l'ambiente "Protetto" o verde** sulla base della semplice presenza dell'applicazione UTM.

4. **Trattamento Sicuro dei File Host:**
   - I file selezionati dall'utente vengono ispezionati staticamente sull'host tramite calcolo crittografico ad anello chiuso (`CryptoKit` SHA-256).
   - **Nessun file selezionato viene mai eseguito o interpretato sull'host macOS.**
   - Il trasferimento verso la sandbox richiede consenso esplicito dell'utente.

---

## 3. Analisi delle Minacce (STRIDE)

| Categoria | Minaccia Specifica | Mitigazione SentinelAI |
| :--- | :--- | :--- |
| **Spoofing** | Falsa identità della VM target o script ostile che impersona la VM di analisi. | Binding univoco all'identificatore della sola VM autorizzata (`authorizedVMName`). Il controller host rifiuta comandi verso macchine virtuali non censite. |
| **Tampering** | Modifica dei file host o iniezione di codice tramite filesystem condiviso. | Divieto assoluto di cartelle condivise e dischi host montati. Base guest usa-e-getta con ripristino da snapshot certificato. |
| **Repudiation** | Azioni non tracciate durante l'analisi comportamentale. | Audit log locale immutabile e sanificato contro escape sequences. Esportazione JSON con timestamp e metadati univoci. |
| **Information Disclosure** | Esfiltrazione di credenziali host o dati personali verso l'esterno. | Zero connessioni verso server cloud proprietari. Modello LLM locale (Ollama opzionale v0.6). Rete VM spenta per impostazione predefinita. |
| **Denial of Service** | Campione che satura la CPU, memoria o tenta il crash del guest. | Timer di sessione con timeout rigido e pulsante immediato **"Ferma analisi"** che invia segnale di arresto pulito o kill della VM designata. |
| **Elevation of Privilege** | Evasione della sandbox UTM verso il kernel di macOS (Hypervisor breakout). | Esecuzione di UTM in spazio utente senza permessi root host; minimizzazione delle superfici I/O virtualizzate (niente USB, niente audio/rete non necessari). |

---

## 4. Classificazione Esplicita degli Esiti

Ogni report generato da SentinelAI distingue tassativamente:
- **Rilevato:** Indicatori certi di ostilità matched da regole deterministiche.
- **Sospetto:** Comportamenti anomali (es. burst I/O in cartelle temporanee, spawn inattesi).
- **Non rilevato:** Nessun indicatore attivato entro la finestra di osservazione stabilita (con disclaimer esplicito sui limiti della scansione dinamica).
- **Non verificabile:** Canale sensore degradato, timeout o snapshot non integro (la policy non assume mai sicurezza in caso di dubbio).
