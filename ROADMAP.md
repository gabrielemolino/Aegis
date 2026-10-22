# 🗺️ Aegis – Project Architecture & Development Roadmap

Welcome to the official architecture and development roadmap of **Aegis**, an autonomous, native macOS sandbox defense and behavioral analysis system engineered for Apple Silicon. This document summarizes the completed system architecture, security guarantees, milestones, and future research horizons.

---

## 🏛️ Completed System Architecture

### 1. Native macOS Host Application Layer (`Sources/SentinelAI/`)
- **SwiftUI Native Interface**: Dark-mode glassmorphic cyber-defense dashboard adhering to Apple Human Interface Guidelines.
- **Reactive Bilingual Localization (`LocalizationManager.swift`)**: Instant runtime language switching (English & Italian) with persistent user preference storage.
- **Fail-Closed Isolation Wizard (`AppState.swift`, `OverviewView.swift`)**: 5-step strict isolation checklist enforcing zero shared folders, zero network, zero clipboard synchronization, zero USB passthrough, and verified clean snapshot.
- **Cryptographic File Ingestion (`CryptoKit`)**: Safe in-memory SHA-256 calculation without executing or parsing untrusted target code on the host Mac.
- **Sanitized Immutable Audit Logger (`AuditLogger.swift`)**: Control-character sanitization, ANSI escape-sequence stripping, append-only memory buffer, and structured JSON / text export.

### 2. Deterministic Rule Engine (`SecurityEngine.swift`)
- **Versioned Rule Catalog**: Real-time evaluation of telemetry events against deterministic detection signatures:
  - `RULE-HEARTBEAT-000`: Fail-closed transition if guest agent heartbeat ceases.
  - `RULE-NET-003`: Immediate critical alert and VM containment on egress network connection attempts.
  - `RULE-PERSIST-002`: Detection of persistence mechanisms in `/etc/cron*`, `systemd`, or init scripts.
  - `RULE-PROC-005`: Interception of suspicious child processes and unexpected script interpreters.
  - `RULE-IO-014`: Sliding-window burst detection for rapid file creations/modifications in `/tmp`.
  - `RULE-INJECT-001`: Treatment of hostile prompt-injection attempts in event logs as strictly passive untrusted data.
- **Zero False Positives on Clean Lifecycles**: Clean baseline processes verified as `Undetected`.

### 3. Disposable Guest Virtualization Layer (`guest-sensor/`)
- **UTM / Apple Virtualization Framework**: Unprivileged user-space virtualization with isolated memory allocation on ARM64.
- **Python 3 Telemetry Sensor (`sentinel_guest_sensor.py`)**:
  - Non-invasive, standard-library-only telemetry monitor running inside Ubuntu ARM64 guest.
  - Real-time polling of `/proc` for new process spawn events and command lines.
  - Monitoring of `/proc/net/tcp` and `/proc/net/udp` for socket establishment attempts.
  - Filesystem modification tracking via `/tmp` directory inspection.
  - Periodic heartbeat generation with strict monotonic sequence numbering.
- **Unidirectional JSONL Telemetry Transport**: Telemetry streams securely into the host without bidirectional shell or file-sharing channels.

### 4. Local Semantic Threat Triage (`LocalLLMService.swift`)
- **On-Device LLM Reasoning (Ollama)**: Local inference using `qwen2.5-coder:3b` executed entirely on the local Apple Silicon GPU via Metal.
- **Zero Cloud Leakage**: No sample attributes, hashes, file names, or telemetry logs are ever transmitted to external servers.
- **Strict JSON Schema Validation**: Automated parsing and conformance checking against rigid structural contracts:
  - `executiveSummary`: Plain-language explanation for security analysts.
  - `mitreAttackTechniques`: Formal MITRE ATT&CK technique mapping (e.g., `T1071.001`, `T1059.004`).
  - `confidenceScore`: Calibrated probability score ($0.0$ to $1.0$).
  - `recommendedAction`: Whitelisted containment action (`STOP_VM`, `CONTINUE_MONITORING`).
- **Anti-Hallucination Guard**: Cross-references LLM-cited event IDs against real ingested events; hallucinated IDs are categorically discarded.

---

## 📅 Release Milestones & Progress

| Milestone | Target | Description | Status |
| :--- | :--- | :--- | :---: |
| **v0.1** | Baseline UI & Safe Read | Native SwiftUI dashboard, safe cryptographic SHA-256 calculation, fail-closed preflight, simulated analysis engine, and sanitized audit logger. | **Completed** |
| **v0.2** | UTM Guided Hardening | 5-step UTM configuration wizard, hardware hardening (no network, no shares, no clipboard, no USB), watchdog query timeout, and rollback policy enforcement (`clean-baseline`). | **Completed** |
| **v0.3** | Deterministic Rule Engine | Versioned rule catalog, event parser, 6 synthetic telemetry datasets, interactive Rule Workbench, and evidence-linking UI. | **Completed** |
| **v0.4** | Host VM Controller | Host controller restricted to authorized VM name (`SentinelAI-Ubuntu-Guest`), rejection of unauthorized VMs, real shutdown confirmation, and post-containment rollback enforcement. | **Completed** |
| **v0.5** | Ephemeral Guest Sensor | Python 3 telemetry agent for Ubuntu ARM64 guest, unidirectional JSONL ingestion, non-simulated real analysis engine. | **Completed** |
| **v0.6** | Local LLM Integration | Local Ollama integration (`qwen2.5-coder:3b`), semantic triage, MITRE ATT&CK mapping, strict JSON schema validation, anti-hallucination guard, and fail-closed fallback. | **Completed** |
| **v0.7** | Public Beta & Distribution | Rebranding to **Aegis**, reactive bilingual UI (Italian & English), explicit limitation of liability clause, 56 unit/E2E tests, and standalone `.app` / `.dmg` / `.zip` packaging script. | **Completed** |

---

## 🔮 Future Research Horizons (v0.8+)

- **eBPF-Based Kernel Probe**: Migration of guest telemetry agent to native eBPF tracepoints (`sys_enter_execve`, `sys_enter_connect`) for kernel-level audit speed and tamper resistance.
- **Automated Memory Snapshot Diffing**: Automated volatility memory comparisons between pre-execution and post-execution guest states.
- **Dynamic Yara Signature Scanning**: Real-time matching of in-memory strings against custom defensive Yara rule catalogs.
- **Pcap Offline Parser**: Passive analysis of virtual TAP adapter packet captures using an offline Rust-based parser.
- **Automated Cuckoo-Compatible API**: Optional REST endpoint for integrating Aegis into automated enterprise malware triage pipelines.
