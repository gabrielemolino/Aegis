# Security Policy

## ⚠️ Limitation of Liability / Legal Disclaimer

> **The author and developers of Aegis expressly disclaim any and all liability and responsibility for any use made of this software, or for any direct, indirect, incidental, special, or consequential damages, loss of data, system malfunctions, or security incidents arising from analyzing, handling, or interacting with potentially malicious, unknown, or hazardous files.**  
> The user assumes sole and exclusive responsibility for their actions, for ensuring the strict isolation of their hardware and network infrastructure, and for compliance with all applicable cybersecurity and computer fraud laws. This software is provided strictly **"AS IS"** for educational, defensive research, security auditing, and controlled sandbox experimentation purposes.
>
> *(Nota in lingua italiana: L'autore e gli sviluppatori di Aegis non sono responsabili per l'uso che l'utente fa del programma né per le conseguenze o danni derivanti dall'analisi di file. L'utente è l'unico ed esclusivo responsabile delle proprie azioni e dell'isolamento del proprio ambiente).*

---

## Supported Versions

| Version | Supported | Notes |
| :--- | :---: | :--- |
| **0.7.x** | ✅ Yes | Current Beta release with Apple Silicon, Bilingual (IT/EN) UI, and Local LLM support. |
| < 0.7.0 | ❌ No | Historical development milestones. |

---

## Reporting a Vulnerability

If you discover a security flaw or vulnerability in Aegis (e.g., a regression in log sanitization against prompt injection, a flaw in the Fail-Closed preflight logic, or an issue in the VM host containment controller), please report it responsibly:

1. **Do NOT open a public GitHub issue.**
2. Submit a private report via [GitHub Security Advisories](https://github.com/gabrielemolino/Aegis/security/advisories/new).
3. Include the following details in your report:
   - A clear description of the vulnerability and its potential impact.
   - Exact steps to reproduce using **strictly synthetic or benign fixtures** (NEVER attach real malware samples or hostile binaries).
   - Expected behavior versus observed behavior on macOS Apple Silicon.

We investigate all legitimate security reports promptly and strive to release verified patches in a timely manner.
