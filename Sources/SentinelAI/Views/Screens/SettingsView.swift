import SwiftUI

public struct SettingsView: View {
    @ObservedObject var appState: AppState
    
    @AppStorage("ollama_endpoint") private var ollamaEndpoint: String = "http://127.0.0.1:11434"
    @AppStorage("enable_local_llm") private var enableLocalLLM: Bool = false
    @AppStorage("telemetry_enabled") private var telemetryEnabled: Bool = false
    @AppStorage("log_retention_days") private var logRetentionDays: Int = 30
    @AppStorage("strict_fail_closed") private var strictFailClosed: Bool = true
    
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
                    Text("Configurazione del modello locale opzionale, ritenzione log e isolamento.")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                }
                
                // Section 1: Analista LLM Locale
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(Theme.accentTeal)
                        Text("Analista LLM Locale (Opzionale)")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Theme.textPrimary)
                        Spacer()
                        StatusBadgeView("Pianificato v0.6", style: .notConfigured)
                    }
                    
                    Toggle("Abilita spiegazione eventi con LLM locale (Ollama)", isOn: $enableLocalLLM)
                        .toggleStyle(.switch)
                        .disabled(true) // Disattivato come da specifica per milestone v0.1
                    
                    Text("Nella milestone v0.1 l'LLM è rigorosamente disattivato. I controlli deterministici e l'isolamento operano in autonomia.")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.textMuted)
                    
                    HStack {
                        Text("Endpoint Ollama locale:")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.textSecondary)
                        Spacer()
                        Text(ollamaEndpoint)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(Theme.textMuted)
                    }
                    .padding(8)
                    .background(Theme.bgDeep)
                    .cornerRadius(4)
                    
                    BannerAlertView(
                        title: "Vincoli di Sicurezza LLM",
                        message: "L'LLM analizzerà solo eventi minimizzati in formato JSON validato. Non riceverà MAI accesso a comandi shell arbitrari o privilegi host.",
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
                
                // Section 2: Privacy e Telemetria
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
                        message: "Nessun file dell'utente o hash viene inviato a server terzi o servizi cloud proprietari. Tutte le verifiche si svolgono al 100% in locale.",
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
                
                // Section 3: Politica di Contenimento e Fail-Closed
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
            .padding(24)
        }
        .background(Theme.bgDeep)
    }
}
