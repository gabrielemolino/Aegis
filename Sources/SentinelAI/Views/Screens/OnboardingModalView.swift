import SwiftUI

public struct OnboardingModalView: View {
    @ObservedObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    public init(appState: AppState) {
        self.appState = appState
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "shield.checkered")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Theme.accentTealBright)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Benvenuto in SentinelAI")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                    Text("Specifiche di Sicurezza e Principi Operativi v0.1")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.textSecondary)
                }
                Spacer()
                
                Button(action: {
                    appState.showOnboardingModal = false
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Theme.textMuted)
                }
                .buttonStyle(.plain)
            }
            .padding(20)
            .background(Theme.surfaceElevated)
            
            Divider().background(Theme.borderSubtle)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // Limiti di Responsabilità
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Obiettivo e Limiti di Responsabilità")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Theme.accentTealBright)
                        
                        Text("SentinelAI è un prototipo tecnico per l'analisi controllata in ambiente isolato (UTM) su macOS Apple Silicon. La priorità è ridurre la superficie d'attacco tramite isolamento rigoroso.")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.textSecondary)
                        
                        BannerAlertView(
                            title: "Cosa SentinelAI NON promette",
                            message: "Non promette protezione assoluta e non sostituisce XProtect, Gatekeeper o il firewall di macOS. Non garantisce che ogni malware venga individuato o che una VM non possa mai essere evasa.",
                            level: .warning
                        )
                    }
                    
                    // Principi Non Negoziabili
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Principi Non Negoziabili del Progetto")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Theme.accentTealBright)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            bulletPoint("1. La sicurezza opera anche se l'LLM è spento, lento, indisponibile o manipolato da prompt injection.")
                            bulletPoint("2. L'LLM analizza e spiega; non riceve mai accesso diretto a shell privilegiate né esegue comandi arbitrari.")
                            bulletPoint("3. Isolamento massimo di default: niente rete, cartelle condivise o clipboard sincronizzata.")
                            bulletPoint("4. Nessun file dell'utente viene eseguito o copiato nella VM senza consenso esplicito.")
                            bulletPoint("5. Nessun malware reale è incluso nel repository o nei test automatici.")
                            bulletPoint("6. Policy Fail-Closed: se la sicurezza della VM non è verificabile, l'analisi non viene avviata.")
                        }
                    }
                    
                    // Stato attuale prerequisiti
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Stato Prerequisiti Host:")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Theme.textPrimary)
                        
                        HStack(spacing: 12) {
                            StatusBadgeView("Apple Silicon: \(appState.prerequisites.architectureName)", style: appState.prerequisites.isAppleSilicon ? .verified : .critical)
                            StatusBadgeView(appState.prerequisites.macOSVersion, style: appState.prerequisites.isMacOSCompatible ? .verified : .manualReview)
                            StatusBadgeView(appState.prerequisites.isUTMInstalled ? "UTM Presente" : "UTM Mancante", style: appState.prerequisites.isUTMInstalled ? .verified : .manualReview)
                        }
                    }
                }
                .padding(20)
            }
            
            Divider().background(Theme.borderSubtle)
            
            // Footer
            HStack {
                Spacer()
                Button(action: {
                    appState.showOnboardingModal = false
                    dismiss()
                }) {
                    Text("Ho compreso i limiti operativi")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Theme.bgDeep)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                        .background(Theme.accentTealBright)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .background(Theme.surfaceElevated)
        }
        .frame(width: 580, height: 500)
        .background(Theme.bgDeep)
    }
    
    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 11))
                .foregroundColor(Theme.accentTeal)
                .padding(.top, 2)
            Text(text)
                .font(.system(size: 11))
                .foregroundColor(Theme.textSecondary)
        }
    }
}
