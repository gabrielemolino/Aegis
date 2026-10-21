# Guida per i Collaboratori / Contributing to Aegis

Grazie per il tuo interesse nel contribuire ad **Aegis**!

Aegis è un progetto open source progettato per l'analisi sicura e il contenimento in sandbox su macOS Apple Silicon. Per preservare l'integrità del progetto e la sicurezza di tutti gli utenti, ogni contributo deve rispettare tassativamente le linee guida seguenti.

---

## 1. Principi di Sicurezza Non Negoziabili

Qualsiasi pull request deve soddisfare e non compromettere i 6 principi cardine:

1. **La sicurezza opera senza LLM:** Il motore deterministico di regole e il contenimento host intervengono autonomamente e non dipendono dall'LLM locale.
2. **Nessun privilegio shell per l'LLM:** L'LLM spiega gli eventi; non riceve mai socket, shell o comandi di sistema.
3. **Isolamento Massimo di Default:** Zero rete, zero cartelle host condivise, zero clipboard condivisa, zero passthrough USB.
4. **Nessuna esecuzione implicita sull'host:** L'ispezione preliminare dei file sull'host è puramente crittografica (calcolo hash SHA-256 in safe-read).
5. **NESSUN MALWARE REALE NEL REPOSITORY:** È severamente vietato effettuare commit o pull request contenenti eseguibili dannosi, payload binari ostili o codice malevolo reale. Utilizzare **esclusivamente** stringhe sintetiche, fixture JSONL o script innocui di simulazione controllata.
6. **Policy Fail-Closed:** In caso di errore o incertezza su prerequisiti o isolamento, l'analisi deve essere bloccata.

---

## 2. Flusso di Sviluppo Locale

### Requisiti
- macOS Sonoma (14.0+) su Apple Silicon (M1/M2/M3/M4/M5).
- Xcode 16+ o Swift 6.0+ toolchain.
- Python 3.10+ (per il sensore guest).
- [Ollama](https://ollama.com/) con modello `qwen2.5-coder:3b` (opzionale per test semantici LLM).

### Istruzioni di compilazione e test
```bash
# 1. Clona il repository
git clone https://github.com/gabrielemolino/Aegis.git
cd Aegis

# 2. Compila in modalità debug
swift build

# 3. Esegui la suite completa di test (50 test unitari ed E2E)
swift test

# 4. Esegui i test del sensore guest Python
python3 guest-sensor/test_sensor.py

# 5. Verifica il packaging macOS (.app, .dmg, .zip)
./scripts/package_macos.sh
```

---

## 3. Supporto Bilingue (Italiano / English)

Aegis supporta nativamente sia l'**Italiano** che l'**Inglese**.  
Se introduci nuove etichette, bottoni o testi nell'interfaccia SwiftUI:
- Aggiungi la chiave sia al dizionario `.italian` che al dizionario `.english` in [`LocalizationManager.swift`](Sources/SentinelAI/Services/LocalizationManager.swift).
- Richiama il testo nelle viste SwiftUI tramite `LocalizationManager.shared.t("chiave")`.

---

## 4. Linee Guida per le Pull Request

1. Crea un branch descrittivo: `feature/nome-funzionalita` o `fix/descrizione-bug`.
2. Aggiungi test specifici per qualsiasi nuova regola deterministica o servizio.
3. Verifica che tutti i 50 test Swift e i 6 test Python passino con zero fallimenti.
4. Apri la Pull Request descrivendo motivazione tecnica, impatto sull'isolamento e test eseguiti.
