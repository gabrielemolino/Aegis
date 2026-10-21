import SwiftUI

public struct SettingsView: View {
    @ObservedObject var appState: AppState
    @ObservedObject private var llmService = LocalLLMService.shared
    
    @AppStorage("telemetry_enabled") private var telemetryEnabled: Bool = false
    @AppStorage("log_retention_days") private var logRetentionDays: Int = 30
    @AppStorage("strict_fail_closed") private var strictFailClosed: Bool = true
    
    @State private var isCheckingConnection: Bool = false
    
    public init(appState: AppState) {
        self.appState = appState
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Impostazioni e Politiche di Sicurezza")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                    Text("Configurazione dell'analista AI locale (Ollama v0.6), ritenzione log e isolamento.")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                }
                
                // Section 1: Analista LLM Locale
                llmSectionView
                
                // Section 2: Privacy e Telemetria
                privacySectionView
                
                // Section 3: Politica di Contenimento e Fail-Closed
                containmentSectionView
            }
            .padding(24)
        }
        .background(Theme.bgDeep)
        .task {
            _ = await llmService.checkOllamaStatus()
        }
    }
    
    // MARK: - Section 1: Analista LLM Locale
    
    @ViewBuilder
    private var llmSectionView: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(Theme.accentTeal)
                Text("Analista LLM Locale (Ollama v0.6)")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                llmStatusBadge
            }
            
            Toggle("Abilita triage semantico e spiegazione tecnica con LLM locale", isOn: $llmService.config.isLLMAnalysisEnabled)
                .toggleStyle(.switch)
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Modello LLM Selezionato:")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                    
                    Picker("", selection: $llmService.config.selectedModel) {
                        Text("qwen2.5-coder:3b (Consigliato per Apple Silicon 8GB)").tag("qwen2.5-coder:3b")
                        Text("qwen2.5:3b (Generico compatto)").tag("qwen2.5:3b")
                        Text("llama3.2:3b (Meta LLaMA 3.2)").tag("llama3.2:3b")
                        Text("mistral:7b (Richiede >8GB RAM)").tag("mistral:7b")
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .frame(maxWidth: 360)
                }
                
                Spacer()
                
                Button(action: {
                    Task {
                        isCheckingConnection = true
                        _ = await llmService.checkOllamaStatus()
                        isCheckingConnection = false
                    }
                }) {
                    HStack(spacing: 6) {
                        if isCheckingConnection {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "arrow.clockwise.circle")
                        }
                        Text("Verifica Connessione")
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Theme.accentTealBright)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Theme.accentTealSubtle)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .disabled(isCheckingConnection)
            }
            
            HStack {
                Text("Endpoint Ollama:")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textSecondary)
                
                TextField("http://127.0.0.1:11434", text: $llmService.config.endpointURLString)
                    .font(.system(size: 11, design: .monospaced))
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 260)
                
                Spacer()
            }
            
            Toggle("Fallback su Simulatore Mock (qwen2.5-coder:3b) se Ollama non risponde", isOn: $llmService.config.isMockFallbackEnabled)
                .toggleStyle(.switch)
            
            Text("Se Ollama è offline o il modello non è presente, il simulatore mock consente di validare la pipeline semantica e i widget MITRE ATT&CK senza bloccare l'interfaccia.")
                .font(.system(size: 11))
                .foregroundColor(Theme.textMuted)
            
            ollamaSetupHelperView
            
            BannerAlertView(
                title: "Architettura di Sicurezza dell'Analista LLM",
                message: "L'LLM è rigorosamente consultivo e privo di capacità di esecuzione comandi. Riceve dati passivi minimizzati e restituisce spiegazioni tecniche strutturate. Le decisioni di contenimento e arresto sono regolate esclusivamente dal motore deterministico.",
                level: .info
            )
        }
        .padding(16)
        .background(Theme.surfaceCard)
        .cornerRadius(Theme.cardCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                .stroke(Theme.borderDefault, lineWidth: 1)
        )
    }
    
    @ViewBuilder
    private var llmStatusBadge: some View {
        if llmService.status == .ready {
            StatusBadgeView("Ollama Online (\(llmService.config.selectedModel))", style: .verified)
        } else if llmService.config.isMockFallbackEnabled {
            StatusBadgeView("Mock \(llmService.config.selectedModel) Attivo", style: .manualReview)
        } else {
            StatusBadgeView("Ollama Offline (:11434)", style: .notConfigured)
        }
    }
    
    @ViewBuilder
    private var ollamaSetupHelperView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Comandi per configurare il modello sul Mac:")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
            
            HStack(spacing: 12) {
                Text("ollama pull \(llmService.config.selectedModel)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(Theme.accentTealBright)
                    .padding(6)
                    .background(Theme.bgDeep)
                    .cornerRadius(4)
                
                Text("ollama run \(llmService.config.selectedModel)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(Theme.textPrimary)
                    .padding(6)
                    .background(Theme.bgDeep)
                    .cornerRadius(4)
            }
        }
        .padding(10)
        .background(Theme.surfaceElevated.opacity(0.4))
        .cornerRadius(6)
    }
    
    // MARK: - Section 2: Privacy e Telemetria
    
    @ViewBuilder
    private var privacySectionView: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "lock.shield.fill")
                    .foregroundColor(Theme.accentTeal)
                Text("Privacy e Ritenzione Dati")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
            }
            
            Toggle("Condivisione telemetria diagnostica anonima (Disattivata per default)", isOn: $telemetryEnabled)
                .toggleStyle(.switch)
            
            HStack {
                Text("Giorni di conservazione audit log locale:")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textSecondary)
                Spacer()
                Picker("", selection: $logRetentionDays) {
                    Text("7 giorni").tag(7)
                    Text("30 giorni").tag(30)
                    Text("90 giorni").tag(90)
                    Text("Illimitata").tag(0)
                }
                .labelsHidden()
                .frame(width: 130)
            }
            
            BannerAlertView(
                title: "Zero Cloud Upload",
                message: "Nessun file dell'utente, hash o telemetria viene inviato a server terzi o servizi cloud proprietari. Tutte le verifiche si svolgono al 100% in locale.",
                level: .info
            )
        }
        .padding(16)
        .background(Theme.surfaceCard)
        .cornerRadius(Theme.cardCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                .stroke(Theme.borderDefault, lineWidth: 1)
        )
    }
    
    // MARK: - Section 3: Politica di Contenimento e Fail-Closed
    
    @ViewBuilder
    private var containmentSectionView: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "exclamationmark.shield.fill")
                    .foregroundColor(Theme.warningAmber)
                Text("Politica Fail-Closed e Contenimento Host")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
            }
            
            Toggle("Blocca rigorosamente l'analisi se manca uno snapshot pulito", isOn: $strictFailClosed)
                .toggleStyle(.switch)
            
            Text("Quando attiva, la policy 'Fail-Closed' impedisce l'avvio dell'analisi se i parametri di sicurezza non sono comprovati in modo inequivocabile.")
                .font(.system(size: 11))
                .foregroundColor(Theme.textMuted)
        }
        .padding(16)
        .background(Theme.surfaceCard)
        .cornerRadius(Theme.cardCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                .stroke(Theme.borderDefault, lineWidth: 1)
        )
    }
}

