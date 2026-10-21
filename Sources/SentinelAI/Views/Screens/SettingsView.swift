import SwiftUI

public struct SettingsView: View {
    @ObservedObject var appState: AppState
    @ObservedObject private var llmService = LocalLLMService.shared
    @ObservedObject private var i18n = LocalizationManager.shared
    
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
                    Text(i18n.t("settings_title"))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                    Text(i18n.t("settings_subtitle"))
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                }
                
                // Section 1: Lingua & Internazionalizzazione
                languageSectionView
                
                // Section 2: Dichiarazione di Non Responsabilità
                liabilityDisclaimerSectionView
                
                // Section 3: Analista LLM Locale
                llmSectionView
                
                // Section 4: Privacy e Telemetria
                privacySectionView
                
                // Section 5: Politica di Contenimento e Fail-Closed
                containmentSectionView
            }
            .padding(24)
        }
        .background(Theme.bgDeep)
        .task {
            _ = await llmService.checkOllamaStatus()
        }
    }
    
    // MARK: - Section 1: Lingua & Localizzazione
    
    @ViewBuilder
    private var languageSectionView: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "globe")
                    .foregroundColor(Theme.accentTeal)
                Text(i18n.t("settings_lang_section_title"))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                StatusBadgeView(i18n.currentLanguage.displayName, style: .verified)
            }
            
            HStack(spacing: 16) {
                Text(i18n.t("settings_lang_label"))
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textSecondary)
                
                Picker("", selection: Binding(
                    get: { i18n.currentLanguage },
                    set: { i18n.setLanguage($0) }
                )) {
                    ForEach(AppLanguage.allCases) { lang in
                        Text("\(lang.flag) \(lang.displayName)").tag(lang)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .frame(width: 240)
                
                Spacer()
            }
            
            Text(i18n.t("settings_lang_desc"))
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
    
    // MARK: - Section 2: Dichiarazione di Non Responsabilità & Esonero Legale
    
    @ViewBuilder
    private var liabilityDisclaimerSectionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(Theme.warningAmber)
                Text(i18n.t("disclaimer_title"))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                StatusBadgeView(i18n.t("disclaimer_badge"), style: .manualReview)
            }
            
            Text(i18n.t("disclaimer_summary"))
                .font(.system(size: 11))
                .foregroundColor(Theme.textSecondary)
                .lineSpacing(3)
                .padding(12)
                .background(Theme.bgDeep)
                .cornerRadius(6)
            
            HStack(spacing: 6) {
                Image(systemName: "hand.raised.shield.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.warningAmber)
                Text("Nota per l'Utente: L'esecuzione o l'analisi di file non fidati avviene sotto la tua esclusiva responsabilità.")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Theme.warningAmber)
            }
            .padding(.top, 2)
        }
        .padding(16)
        .background(Theme.warningAmber.opacity(0.05))
        .cornerRadius(Theme.cardCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                .stroke(Theme.warningAmber.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Section 3: Analista LLM Locale
    
    @ViewBuilder
    private var llmSectionView: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(Theme.accentTeal)
                Text(i18n.t("settings_llm_section_title"))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                llmStatusBadge
            }
            
            Toggle(i18n.t("settings_llm_toggle"), isOn: $llmService.config.isLLMAnalysisEnabled)
                .toggleStyle(.switch)
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(i18n.t("settings_llm_model_label"))
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                    
                    Picker("", selection: $llmService.config.selectedModel) {
                        Text("qwen2.5-coder:3b (Apple Silicon 8GB)").tag("qwen2.5-coder:3b")
                        Text("qwen2.5:3b (Generico)").tag("qwen2.5:3b")
                        Text("llama3.2:3b (Meta LLaMA 3.2)").tag("llama3.2:3b")
                        Text("mistral:7b (>8GB RAM)").tag("mistral:7b")
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
                        Text(i18n.t("settings_llm_check_conn"))
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
                Text(i18n.t("settings_llm_endpoint_label"))
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textSecondary)
                
                TextField("http://127.0.0.1:11434", text: $llmService.config.endpointURLString)
                    .font(.system(size: 11, design: .monospaced))
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 260)
                
                Spacer()
            }
            
            Toggle(i18n.t("settings_llm_mock_toggle"), isOn: $llmService.config.isMockFallbackEnabled)
                .toggleStyle(.switch)
            
            Text(i18n.t("settings_llm_mock_desc"))
                .font(.system(size: 11))
                .foregroundColor(Theme.textMuted)
            
            ollamaSetupHelperView
            
            BannerAlertView(
                title: i18n.t("settings_llm_banner_title"),
                message: i18n.t("settings_llm_banner_msg"),
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
            Text(i18n.t("settings_llm_commands_hint"))
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
    
    // MARK: - Section 4: Privacy e Telemetria
    
    @ViewBuilder
    private var privacySectionView: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "lock.shield.fill")
                    .foregroundColor(Theme.accentTeal)
                Text(i18n.t("settings_privacy_title"))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
            }
            
            Toggle(i18n.t("settings_telemetry_toggle"), isOn: $telemetryEnabled)
                .toggleStyle(.switch)
            
            HStack {
                Text(i18n.t("settings_log_retention_label"))
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
                title: i18n.t("settings_zero_cloud_title"),
                message: i18n.t("settings_zero_cloud_msg"),
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
    
    // MARK: - Section 5: Politica di Contenimento e Fail-Closed
    
    @ViewBuilder
    private var containmentSectionView: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "exclamationmark.shield.fill")
                    .foregroundColor(Theme.warningAmber)
                Text(i18n.t("settings_containment_title"))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
            }
            
            Toggle(i18n.t("settings_containment_toggle"), isOn: $strictFailClosed)
                .toggleStyle(.switch)
            
            Text(i18n.t("settings_containment_desc"))
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


