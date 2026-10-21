# Politica di Sicurezza / Security Policy

## ⚠️ Clausola di Esonero di Responsabilità / Legal Disclaimer

> **ITALIANO:**  
> **L'autore e gli sviluppatori di Aegis declinano ogni responsabilità per l'uso che l'utente fa del software e per qualsiasi conseguenza, danno diretto o indiretto, perdita di dati o malfunzionamento del sistema che possa derivare dall'analisi, gestione o manipolazione di file potenzialmente malevoli o sconosciuti.**  
> L'utente è l'unico ed esclusivo responsabile delle proprie azioni, dell'isolamento della propria infrastruttura e della conformità alle leggi vigenti in materia di sicurezza informatica. Il software è fornito "COSÌ COM'È" a scopo di ricerca difensiva, audit e analisi controllata in sandbox.
>
> **ENGLISH:**  
> **The author and developers of Aegis disclaim all liability and responsibility for any use made of this software by the user, or for any consequences, direct or indirect damages, data loss, or system issues arising from analyzing, handling, or interacting with potentially malicious or unknown files.**  
> The user assumes sole responsibility for their actions, environment isolation, and compliance with applicable cybersecurity regulations. The software is provided "AS IS" for defensive research, auditing, and controlled sandbox analysis.

---

## Versioni Supportate / Supported Versions

| Versione / Version | Supporto / Supported | Note / Notes |
| :--- | :--- | :--- |
| **0.7.x** | ✅ Sì / Yes | Versione Beta corrente con supporto Apple Silicon, Bilinguismo e LLM locale. |
| < 0.7.0 | ❌ No | Versioni architetturali precedenti ad uso transitorio. |

---

## Segnalazione di Vulnerabilità / Reporting a Vulnerability

Se ritieni di aver identificato una vulnerabilità di sicurezza in Aegis (ad esempio una regressione nella sanitizzazione dei log contro Prompt Injection, una debolezza nelle policy di Fail-Closed o una vulnerabilità nel controller della VM), ti invitiamo a segnalarla in modo responsabile:

1. **Non aprire una issue pubblica su GitHub.**
2. Invia una segnalazione dettagliata via email all'indirizzo del maintainer o apri una [GitHub Security Advisory privata](https://github.com/gabrielemolino/Aegis/security/advisories/new).
3. Includi nella segnalazione:
   - Una descrizione dettagliata del difetto.
   - I passaggi per riprodurlo utilizzando esclusivamente **fixture o payload sintetici innocui** (NON inviare malware reale).
   - L'impatto potenziale sull'host macOS o sull'ambiente guest.

Ci impegniamo a prendere in carico la segnalazione tempestivamente e a rilasciare patch correttive nel minor tempo possibile.
