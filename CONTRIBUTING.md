# Contributing to Aegis

Thank you for your interest in contributing to **Aegis**!

Aegis is an open-source security tool designed for safe file inspection and sandbox containment on macOS Apple Silicon. To preserve the integrity and security of the project, all contributions must strictly adhere to the following guidelines.

---

## 1. Non-Negotiable Security Principles

Any contribution or pull request must uphold the 6 fundamental principles:

1. **Safety Operates Without LLM:** Deterministic rule evaluation and host containment execute independently. The core defense system functions fully even if the LLM is offline or high-latency.
2. **Zero Shell Privileges for the LLM:** The LLM is strictly an analytical observer. It never receives interactive shell access, privileged sockets, or execution rights.
3. **Maximum Default Isolation:** No network connectivity, no shared host folders, no shared clipboard, and no USB passthrough.
4. **No Implicit Host Execution:** Target files undergo cryptographic inspection (SHA-256) on the host macOS via safe read-only operations. No sample is ever executed on the host Mac.
5. **ZERO REAL MALWARE IN REPOSITORY:** It is strictly prohibited to commit or open pull requests containing hostile binaries, functional exploits, or real malware payloads. Use **strictly synthetic** event strings, JSONL fixtures, or benign simulation scripts.
6. **Fail-Closed Policy:** If any security prerequisite or VM isolation state cannot be deterministically verified, the analysis must be blocked.

---

## 2. Local Development Workflow

### Requirements
- macOS 14 (Sonoma) or newer on Apple Silicon (M1/M2/M3/M4/M5).
- Xcode 16.0+ or Swift 6.0+ toolchain.
- Python 3.10+ (for the guest sensor).
- [Ollama](https://ollama.com/) with model `qwen2.5-coder:3b` (optional for local LLM evaluation).

### Build and Test Instructions
```bash
# 1. Clone your fork of the repository
git clone https://github.com/gabrielemolino/Aegis.git
cd Aegis

# 2. Build in debug mode
swift build

# 3. Run the complete test suite (50 Swift unit & E2E tests)
swift test

# 4. Run the guest sensor validation tests (Python 3)
python3 guest-sensor/test_sensor.py

# 5. Verify the standalone macOS packaging script (.app, .dmg, .zip)
./scripts/package_macos.sh
```

---

## 3. Bilingual Support (English & Italian)

Aegis provides native bilingual UI localization.  
When adding or updating user-facing UI labels, buttons, or error messages:
- Add the corresponding key to both the `.english` and `.italian` dictionaries in [`LocalizationManager.swift`](Sources/SentinelAI/Services/LocalizationManager.swift).
- Reference the string in SwiftUI views via `LocalizationManager.shared.t("your_key")`.

---

## 4. Pull Request Guidelines

1. Create a descriptive feature branch: `feature/your-feature-name` or `fix/issue-description`.
2. Write unit tests for any new deterministic rules, telemetry parsers, or services.
3. Verify that all 50 Swift tests and 6 Python tests pass locally with **zero failures**.
4. Submit the Pull Request referencing any relevant issues, explaining the defensive rationale and isolation impact.
