# Aegis — Threat Model & Security Architecture

**Version:** 0.7 (Beta Release)  
**Target:** macOS on Apple Silicon (arm64)  
**Isolated Environment:** UTM Virtualization (QEMU / Apple Virtualization Framework)  

---

## ⚠️ Legal Disclaimer & Limitation of Liability

> **The author and developers of Aegis expressly disclaim any and all liability and responsibility for any use made of this software, or for any direct, indirect, incidental, special, or consequential damages, loss of data, system malfunctions, or security incidents arising from analyzing, handling, or interacting with potentially malicious, unknown, or hazardous files.**  
> The software is designed strictly as a defensive inspection tool. Any handling of suspicious or malicious files is conducted under the **sole and exclusive responsibility of the user**, who must independently verify the security posture and physical isolation of their environment.

---

## 1. Security Objective & Defense Posture

Aegis is designed to analyze suspicious files and workloads while minimizing the attack surface against the macOS host.

> **Fundamental Assumption:** No software isolation or hypervisor is theoretically immune from hypervisor breakout or zero-day vulnerabilities. Aegis **does not** promise absolute immunity nor replace built-in macOS platform defenses (XProtect, Gatekeeper, MRT, Firewall). Its engineering focus is **deterministic containment**, **privilege separation**, and **strict Fail-Closed operation**.

---

## 2. Non-Negotiable Architecture Principles

1. **LLM Decoupled from Direct System Action:**
   - The LLM operates strictly as an analyst and semantic explainer.
   - The LLM **never receives interactive shell access, privileged sockets, or system execution capabilities**.
   - Containment actions (e.g., immediate VM shutdown) are written in native Swift, enforced by a strict allowlist, and triggered by a deterministic rule engine regardless of LLM availability or latency.
   - Protection against Prompt Injection: all telemetry output originating from guest processes, files, or logs is treated as **untrusted passive data** and validated against rigid JSON schemas.

2. **Strict Default Isolation (UTM Sandboxing):**
   - **Network:** Disconnected by default. No bridged interfaces onto local LANs or the Internet.
   - **Shared Folders:** Disabled. No host volumes (Desktop, Downloads, Documents) mounted via WebDAV, VirtFS, or 9p.
   - **Clipboard & Drag-and-Drop:** Disabled to eliminate unintended payload transfers.
   - **USB Devices:** No USB passthrough permitted.
   - **Disposable:** Analysis is conducted exclusively on ephemeral guest clones or rollback-capable snapshots.

3. **Fail-Closed Policy (Blocking Preflight):**
   - If any isolation check cannot be deterministically verified, the system **blocks analysis execution** and marks the environment as `Manual Verification Required`.
   - The application **never marks the environment as "Protected" or green** simply because UTM is installed.

4. **Safe Host File Handling:**
   - User-selected target files undergo static cryptographic inspection on the host via in-memory hashing (`CryptoKit` SHA-256).
   - **No target file is ever executed, run, or interpreted on the host macOS.**
   - Transfer to the sandbox requires explicit user approval.

---

## 3. STRIDE Threat Analysis

| Category | Specific Threat | Aegis Mitigation |
| :--- | :--- | :--- |
| **Spoofing** | Rogue VM or script spoofing the designated analysis target. | Strict binding to the unique identifier of the authorized VM (`authorizedVMName`). The host controller categorically rejects commands targeted at non-whitelisted virtual machines. |
| **Tampering** | Host filesystem modification or payload injection via shared drives. | Absolute prohibition of shared folders and mounted host disks. Disposable guest filesystem restored from clean snapshot (`clean-baseline`). |
| **Repudiation** | Untracked activity during dynamic behavioral execution. | Append-only, local audit logger sanitized against escape sequence injections. Structured JSON exports with timestamps and cryptographically hashed event sequences. |
| **Information Disclosure** | Exfiltration of host credentials or personal data. | Zero telemetry transmission to third-party or cloud servers. Optional local LLM running on-device (`qwen2.5-coder:3b` via Ollama). Virtual machine network adapter turned off by default. |
| **Denial of Service** | Malicious workload attempting host resource starvation or guest crash. | Strict watchdog session timers, non-blocking execution, and an immediate **"Emergency Stop"** control that terminates the VM. |
| **Elevation of Privilege** | Sandbox escape from guest kernel to macOS host (Hypervisor breakout). | UTM runs entirely in unprivileged user space without host root permissions; minimization of virtualized device drivers (no USB, no audio, no extraneous hardware). |

---

## 4. Explicit Classification Outcomes

Every analysis report generated by Aegis provides one of four deterministic outcomes:
- **Detected:** Confirmed indicators of compromise matched by deterministic rules (e.g., unexpected interpreter spawning, egress network attempts, rapid file bursts in `/tmp`).
- **Suspicious:** Anomalous behavioral patterns requiring manual scrutiny.
- **Undetected:** No malicious indicators triggered within the observation window (accompanied by explicit disclaimers regarding the inherent limits of dynamic sandboxing).
- **Unverifiable:** Telemetry channel degraded, sensor heartbeat lost, or snapshot verification failed (Fail-Closed: safety is never assumed).
