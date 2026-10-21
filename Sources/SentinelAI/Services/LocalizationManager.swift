import Foundation
import SwiftUI
import Combine

/// Lingua supportata dall'applicazione Aegis (v0.7)
public enum AppLanguage: String, Codable, CaseIterable, Identifiable, Sendable {
    case italian = "it"
    case english = "en"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .italian: return "Italiano"
        case .english: return "English"
        }
    }
    
    public var flag: String {
        switch self {
        case .italian: return "🇮🇹"
        case .english: return "🇬🇧"
        }
    }
}

/// Gestore centralizzato e reattivo delle traduzioni e della localizzazione di Aegis (Milestone v0.7)
@MainActor
public final class LocalizationManager: ObservableObject {
    public static let shared = LocalizationManager()
    
    private let storageKey = "aegis_app_language"
    
    @Published public var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: storageKey)
        }
    }
    
    public init() {
        if let saved = UserDefaults.standard.string(forKey: "aegis_app_language"),
           let lang = AppLanguage(rawValue: saved) {
            self.currentLanguage = lang
        } else {
            // Default iniziale: Italiano con opzione di scelta all'onboarding
            self.currentLanguage = .italian
        }
    }
    
    /// Imposta la lingua attiva
    public func setLanguage(_ language: AppLanguage) {
        self.currentLanguage = language
    }
    
    /// Traduzione rapida di una chiave
    public func t(_ key: String) -> String {
        if let val = strings[currentLanguage]?[key] {
            return val
        }
        if let fallback = strings[.italian]?[key] {
            return fallback
        }
        return key
    }
    
    // MARK: - Dizionario delle Traduzioni
    
    private let strings: [AppLanguage: [String: String]] = [
        .italian: [
            // App branding
            "app_name": "Aegis",
            "app_subtitle": "macOS Sandbox Defense",
            "app_tagline": "Piattaforma di analisi comportamentale e contenimento in sandbox per Apple Silicon",
            
            // Sidebar Tabs
            "tab_overview": "Panoramica",
            "tab_sandbox": "Sandbox",
            "tab_analysis": "Analisi",
            "tab_events": "Eventi",
            "tab_settings": "Impostazioni",
            
            // Sidebar footer
            "sidebar_host_silicon": "Host: Apple Silicon",
            "sidebar_utm_detected": "UTM Rilevato",
            "sidebar_utm_missing": "UTM non rilevato",
            "sidebar_limits_threat_model": "Limiti & Threat Model",
            
            // Legal Disclaimer / Limitation of Liability
            "disclaimer_title": "Dichiarazione di Non Responsabilità & Esonero Legale",
            "disclaimer_badge": "Esonero Legale",
            "disclaimer_summary": "L'autore e gli sviluppatori di Aegis declinano esplicitamente ogni responsabilità civile, penale o economica per qualsiasi danno diretto, indiretto o consequenziale (inclusi, senza limitazioni, perdita di dati, arresto operativo, alterazione di file di sistema o compromissione dell'ambiente host) derivante dall'uso o dall'impossibilità di usare il software, nonché per l'eventuale manipolazione o esecuzione di campioni potenzialmente dannosi. L'utente accetta di utilizzare Aegis esclusivamente a proprio rischio, sotto la propria autonoma responsabilità e all'interno di un perimetro controllato conforme alle leggi vigenti.",
            "disclaimer_checkbox": "Ho compreso e accetto che l'autore non è responsabile per l'uso dell'applicazione o per qualsiasi conseguenza derivante dall'analisi dei file.",
            "disclaimer_button_accept": "Accetto i termini e avvia Aegis",
            
            // Onboarding
            "onboarding_welcome": "Benvenuto in Aegis",
            "onboarding_version_title": "Specifiche di Sicurezza e Principi Operativi v0.7",
            "onboarding_language_prompt": "Seleziona la lingua dell'interfaccia / Select interface language:",
            "onboarding_scope_title": "Obiettivo e Postura di Difesa",
            "onboarding_scope_desc": "Aegis è una piattaforma tecnica per l'analisi controllata in ambiente isolato (UTM) su macOS Apple Silicon. La priorità è ridurre la superficie d'attacco tramite isolamento rigoroso (Fail-Closed).",
            "onboarding_not_promised_title": "Cosa Aegis NON promette",
            "onboarding_not_promised_msg": "Non promette protezione assoluta e non sostituisce XProtect, Gatekeeper o il firewall di macOS. Non garantisce che ogni malware venga individuato o che una VM non possa mai essere evasa.",
            "onboarding_principles_title": "Principi Non Negoziabili del Progetto",
            "onboarding_rule_1": "1. La sicurezza opera anche se l'LLM è spento, lento, indisponibile o manipolato da prompt injection.",
            "onboarding_rule_2": "2. L'LLM analizza e spiega; non riceve mai accesso diretto a shell privilegiate né esegue comandi arbitrari.",
            "onboarding_rule_3": "3. Isolamento massimo di default: niente rete, cartelle condivise o clipboard sincronizzata.",
            "onboarding_rule_4": "4. Nessun file dell'utente viene eseguito o copiato nella VM senza consenso esplicito.",
            "onboarding_rule_5": "5. Nessun malware reale è incluso nel repository o nei test automatici.",
            "onboarding_rule_6": "6. Policy Fail-Closed: se la sicurezza della VM non è verificabile, l'analisi viene tassativamente bloccata.",
            
            // Overview
            "overview_title": "Panoramica",
            "overview_subtitle": "Stato operativo dell'host e configurazione della sandbox di contenimento.",
            "overview_banner_title": "Piattaforma di Sicurezza Aegis v0.7",
            "overview_banner_desc": "Aegis isola i file sospetti in una VM dedicata per limitare la superficie d'attacco. Non sostituisce XProtect, Gatekeeper o il firewall di macOS.",
            "overview_card_utm_title": "Sandbox UTM",
            "overview_card_rules_title": "Motore di Rilevamento",
            "overview_card_llm_title": "Analista AI Locale",
            "overview_explore_rules": "Esplora catalogo regole →",
            "overview_configure_env": "Configura ambiente →",
            "overview_configure_model": "Configura modello →",
            "overview_checklist_title": "Controlli di Isolamento Host/Guest",
            "overview_fail_closed_active": "Policy Fail-Closed Attiva",
            "overview_recent_activity": "Attività Recenti",
            "overview_start_new_analysis": "Avvia nuova analisi",
            "overview_no_analyses": "Nessuna analisi eseguita",
            "overview_no_analyses_sub": "Seleziona un file da verificare in modalità isolata per avviare il preflight.",
            
            // Settings
            "settings_title": "Impostazioni e Politiche di Sicurezza",
            "settings_subtitle": "Lingua interfaccia, configurazione analista AI locale (Ollama), ritenzione log e clausole legali.",
            "settings_lang_section_title": "Lingua Interfaccia & Internazionalizzazione",
            "settings_lang_label": "Lingua applicazione:",
            "settings_lang_desc": "Puoi modificare la lingua in qualsiasi momento. La modifica viene applicata istantaneamente a tutti i menu e schermi.",
            "settings_llm_section_title": "Analista LLM Locale (Ollama v0.7)",
            "settings_llm_toggle": "Abilita triage semantico e spiegazione tecnica con LLM locale",
            "settings_llm_model_label": "Modello LLM Selezionato:",
            "settings_llm_check_conn": "Verifica Connessione",
            "settings_llm_endpoint_label": "Endpoint Ollama:",
            "settings_llm_mock_toggle": "Fallback su Simulatore Mock (qwen2.5-coder:3b) se Ollama non risponde",
            "settings_llm_mock_desc": "Se Ollama è offline o il modello non è presente, il simulatore mock consente di validare la pipeline semantica e i widget MITRE ATT&CK senza bloccare l'interfaccia.",
            "settings_llm_commands_hint": "Comandi per configurare il modello sul Mac:",
            "settings_llm_banner_title": "Architettura di Sicurezza dell'Analista LLM",
            "settings_llm_banner_msg": "L'LLM è rigorosamente consultivo e privo di capacità di esecuzione comandi. Riceve dati passivi minimizzati e restituisce spiegazioni tecniche strutturate. Le decisioni di contenimento e arresto sono regolate esclusivamente dal motore deterministico.",
            "settings_privacy_title": "Privacy e Ritenzione Dati",
            "settings_telemetry_toggle": "Condivisione telemetria diagnostica anonima (Disattivata per default)",
            "settings_log_retention_label": "Giorni di conservazione audit log locale:",
            "settings_zero_cloud_title": "Zero Cloud Upload",
            "settings_zero_cloud_msg": "Nessun file dell'utente, hash o telemetria viene inviato a server terzi o servizi cloud proprietari. Tutte le verifiche si svolgono al 100% in locale.",
            "settings_containment_title": "Politica Fail-Closed e Contenimento Host",
            "settings_containment_toggle": "Blocca rigorosamente l'analisi se manca uno snapshot pulito",
            "settings_containment_desc": "Quando attiva, la policy 'Fail-Closed' impedisce l'avvio dell'analisi se i parametri di sicurezza non sono comprovati in modo inequivocabile.",
            
            // Analysis Screen
            "analysis_title": "Analisi e Contenimento",
            "analysis_subtitle": "Verifica statica sicura su host ed esecuzione controllata in sandbox isolata.",
            "analysis_stop_btn": "Ferma analisi",
            "analysis_card_1_title": "1. Selezione File da Analizzare",
            "analysis_choose_file_btn": "Scegli file dal Mac...",
            "analysis_safe_guarantee_title": "Garanzia di Sicurezza Host",
            "analysis_safe_guarantee_msg": "Il file selezionato viene sottoposto unicamente a calcolo crittografico di impronta (SHA-256). Nessun codice viene eseguito sull'ambiente host macOS.",
            "analysis_start_btn": "Verifica Preflight e Avvia Analisi",
            "analysis_outcome": "Esito Analisi:",
            "analysis_confidence": "Livello Confidenza",
            "analysis_evidence_observed": "Evidenze Osservate:",
            "analysis_rules_triggered": "Regole Deterministiche Attivate:",
            "analysis_actions_executed": "Azioni di Contenimento Eseguite:",
            "analysis_ai_triage": "Triage Semantico AI:",
            "analysis_mitre_techniques": "Tecniche MITRE ATT&CK Mappate:",
            "analysis_confirmed_evidence": "Evidenze confermate (Anti-Allucinazione):",
            "analysis_ai_advisory": "Analisi consultiva: zero esecuzione di comandi arbitrari sull'host o sul guest.",
            "analysis_limitations_title": "Limiti dell'Analisi (Dichiarazione Esplicita):"
        ],
        .english: [
            // App branding
            "app_name": "Aegis",
            "app_subtitle": "macOS Sandbox Defense",
            "app_tagline": "Behavioral analysis and containment platform in isolated sandbox for Apple Silicon",
            
            // Sidebar Tabs
            "tab_overview": "Overview",
            "tab_sandbox": "Sandbox",
            "tab_analysis": "Analysis",
            "tab_events": "Events",
            "tab_settings": "Settings",
            
            // Sidebar footer
            "sidebar_host_silicon": "Host: Apple Silicon",
            "sidebar_utm_detected": "UTM Detected",
            "sidebar_utm_missing": "UTM Not Detected",
            "sidebar_limits_threat_model": "Limits & Threat Model",
            
            // Legal Disclaimer / Limitation of Liability
            "disclaimer_title": "Limitation of Liability & Legal Disclaimer",
            "disclaimer_badge": "Legal Disclaimer",
            "disclaimer_summary": "The author and developers of Aegis explicitly disclaim all civil, criminal, or financial liability for any direct, indirect, or consequential damages (including, without limitation, loss of data, operational downtime, system file alteration, or host compromise) resulting from the use or inability to use the software, as well as the handling or execution of potentially malicious samples. The user agrees to operate Aegis solely at their own risk, under their sole responsibility, and within a controlled environment adhering to applicable laws.",
            "disclaimer_checkbox": "I understand and agree that the author is not responsible for the user's actions, use of the software, or any consequences resulting from file analysis.",
            "disclaimer_button_accept": "I Agree to Terms & Launch Aegis",
            
            // Onboarding
            "onboarding_welcome": "Welcome to Aegis",
            "onboarding_version_title": "Security Specifications & Operational Principles v0.7",
            "onboarding_language_prompt": "Select interface language / Seleziona la lingua dell'interfaccia:",
            "onboarding_scope_title": "Scope & Defense Posture",
            "onboarding_scope_desc": "Aegis is a technical platform for controlled analysis within an isolated environment (UTM) on macOS Apple Silicon. Priority is attack surface reduction via strict isolation (Fail-Closed).",
            "onboarding_not_promised_title": "What Aegis DOES NOT Promise",
            "onboarding_not_promised_msg": "It does not promise absolute protection and does not replace macOS XProtect, Gatekeeper, or Firewall. It cannot guarantee all malware will be detected or that a VM hypervisor can never be escaped.",
            "onboarding_principles_title": "Non-Negotiable Project Principles",
            "onboarding_rule_1": "1. Safety operates even if the local LLM is offline, slow, unavailable, or targeted by prompt injection.",
            "onboarding_rule_2": "2. The LLM only analyzes and explains; it never receives shell privileges or command execution rights.",
            "onboarding_rule_3": "3. Maximum isolation by default: no network, no shared folders, no clipboard sharing.",
            "onboarding_rule_4": "4. User files are never executed or transferred to the VM without explicit user consent.",
            "onboarding_rule_5": "5. No real malware is included in the repository or automated test suites.",
            "onboarding_rule_6": "6. Fail-Closed Policy: if VM security cannot be verified, analysis is strictly blocked.",
            
            // Overview
            "overview_title": "Overview",
            "overview_subtitle": "Operational host status and isolated containment sandbox configuration.",
            "overview_banner_title": "Aegis Security Platform v0.7",
            "overview_banner_desc": "Aegis isolates suspicious files in a dedicated VM to limit attack surface. It does not replace macOS XProtect, Gatekeeper, or Firewall.",
            "overview_card_utm_title": "UTM Sandbox",
            "overview_card_rules_title": "Detection Engine",
            "overview_card_llm_title": "Local AI Analyst",
            "overview_explore_rules": "Explore rules catalog →",
            "overview_configure_env": "Configure environment →",
            "overview_configure_model": "Configure model →",
            "overview_checklist_title": "Host/Guest Isolation Checks",
            "overview_fail_closed_active": "Fail-Closed Policy Active",
            "overview_recent_activity": "Recent Activity",
            "overview_start_new_analysis": "Start new analysis",
            "overview_no_analyses": "No analysis performed yet",
            "overview_no_analyses_sub": "Select a file to inspect in isolated mode to begin preflight checks.",
            
            // Settings
            "settings_title": "Settings & Security Policies",
            "settings_subtitle": "Interface language, local AI analyst (Ollama), log retention, and legal disclaimers.",
            "settings_lang_section_title": "Interface Language & Localization",
            "settings_lang_label": "Application language:",
            "settings_lang_desc": "You can change the language at any time. Changes apply instantly across all menus and views.",
            "settings_llm_section_title": "Local LLM Analyst (Ollama v0.7)",
            "settings_llm_toggle": "Enable semantic triage and technical explanation with local LLM",
            "settings_llm_model_label": "Selected LLM Model:",
            "settings_llm_check_conn": "Check Connection",
            "settings_llm_endpoint_label": "Ollama Endpoint:",
            "settings_llm_mock_toggle": "Fallback to Mock Simulator (qwen2.5-coder:3b) if Ollama is unreachable",
            "settings_llm_mock_desc": "If Ollama is offline or model is missing, mock simulator enables testing semantic triage and MITRE ATT&CK widgets without blocking the UI.",
            "settings_llm_commands_hint": "Terminal commands to setup the model on your Mac:",
            "settings_llm_banner_title": "LLM Analyst Security Architecture",
            "settings_llm_banner_msg": "The LLM is strictly advisory and has zero command execution privileges. It receives passive data and outputs structured technical reasoning. Containment decisions are governed strictly by the deterministic engine.",
            "settings_privacy_title": "Privacy & Data Retention",
            "settings_telemetry_toggle": "Share anonymous diagnostic telemetry (Disabled by default)",
            "settings_log_retention_label": "Local audit log retention days:",
            "settings_zero_cloud_title": "Zero Cloud Upload",
            "settings_zero_cloud_msg": "No user files, hashes, or telemetry are ever sent to third-party servers or proprietary clouds. All verification takes place 100% locally.",
            "settings_containment_title": "Fail-Closed Policy & Host Containment",
            "settings_containment_toggle": "Strictly block analysis if clean snapshot is unconfirmed",
            "settings_containment_desc": "When active, 'Fail-Closed' policy halts analysis whenever security baseline cannot be verified without ambiguity.",
            
            // Analysis Screen
            "analysis_title": "Analysis & Containment",
            "analysis_subtitle": "Safe static inspection on host and controlled execution in isolated sandbox.",
            "analysis_stop_btn": "Stop analysis",
            "analysis_card_1_title": "1. Target File Selection",
            "analysis_choose_file_btn": "Choose file from Mac...",
            "analysis_safe_guarantee_title": "Host Security Guarantee",
            "analysis_safe_guarantee_msg": "Selected file undergoes cryptographic SHA-256 calculation only. No code is executed on the host macOS environment.",
            "analysis_start_btn": "Verify Preflight & Begin Analysis",
            "analysis_outcome": "Analysis Outcome:",
            "analysis_confidence": "Confidence Score",
            "analysis_evidence_observed": "Observed Evidence:",
            "analysis_rules_triggered": "Triggered Deterministic Rules:",
            "analysis_actions_executed": "Executed Containment Actions:",
            "analysis_ai_triage": "AI Semantic Triage:",
            "analysis_mitre_techniques": "Mapped MITRE ATT&CK Techniques:",
            "analysis_confirmed_evidence": "Confirmed Evidence (Anti-Hallucination):",
            "analysis_ai_advisory": "Advisory analysis only: zero arbitrary command execution on host or guest.",
            "analysis_limitations_title": "Analysis Limitations (Explicit Disclosure):"
        ]
    ]
}
