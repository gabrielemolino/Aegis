import SwiftUI
import AppKit

public struct AnalysisView: View {
    @ObservedObject var appState: AppState
    @ObservedObject private var securityEngine = SecurityEngine.shared
    
    @State private var showPreflightErrorModal: Bool = false
    @State private var samplePathInput: String = ""
    @State private var telemetryInputMode: Int = 0 // 0: Fixture sintetica, 1: Telemetria Guest (.jsonl)
    
    public init(appState: AppState) {
        self.appState = appState
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Analisi e Contenimento")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Theme.textPrimary)
                        Text("Verifica statica sicura su host ed esecuzione controllata in sandbox isolata.")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.textSecondary)
                    }
                    Spacer()
                    
                    if securityEngine.isAnalysisActive {
                        Button(action: {
                            appState.stopAnalysis()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "stop.circle.fill")
                                Text("Ferma analisi")
                            }
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Theme.textPrimary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Theme.criticalRed)
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                // Card 1: Selettore File Sicuro
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("1. Selezione File da Analizzare")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Theme.textPrimary)
                        Spacer()
                        
                        Button(action: {
                            openNativeFilePicker()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "doc.badge.plus")
                                Text("Scegli file dal Mac...")
                            }
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Theme.accentTealBright)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Theme.accentTealSubtle)
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    if let target = appState.targetFile {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "doc.text.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(Theme.accentTeal)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(target.name)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(Theme.textPrimary)
                                    Text("Percorso: \(target.path)")
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(Theme.textMuted)
                                }
                                Spacer()
                                StatusBadgeView("File Statico (Non eseguito)", style: .neutral)
                            }
                            .padding(10)
                            .background(Theme.bgDeep)
                            .cornerRadius(6)
                            
                            HStack(spacing: 20) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Dimensione")
                                        .font(.system(size: 10))
                                        .foregroundColor(Theme.textMuted)
                                    Text(target.formattedSize)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(Theme.textPrimary)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Hash SHA-256 (Calcolato in locale)")
                                        .font(.system(size: 10))
                                        .foregroundColor(Theme.textMuted)
                                    Text(target.sha256)
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(Theme.accentTealBright)
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                    } else {
                        // Demo selector for testing without requiring a malicious file
                        VStack(spacing: 8) {
                            Text("Nessun file selezionato. Seleziona un file dal Mac oppure usa un fixture di test simulato:")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.textSecondary)
                            
                            HStack(spacing: 10) {
                                Button(action: {
                                    loadMockFixtureFile(name: "sample_installer_payload.pkg")
                                }) {
                                    Text("Carica Fixture: Installer Package")
                                        .font(.system(size: 11, weight: .medium))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Theme.surfaceElevated)
                                        .cornerRadius(4)
                                }
                                .buttonStyle(.plain)
                                
                                Button(action: {
                                    loadMockFixtureFile(name: "test_utility_script.sh")
                                }) {
                                    Text("Carica Fixture: Utility Script")
                                        .font(.system(size: 11, weight: .medium))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Theme.surfaceElevated)
                                        .cornerRadius(4)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Theme.surfaceElevated.opacity(0.3))
                        .cornerRadius(6)
                    }
                    
                    BannerAlertView(
                        title: "Garanzia di Sicurezza Host",
                        message: "Il file selezionato viene sottoposto unicamente a calcolo crittografico di impronta (SHA-256). Nessun codice viene eseguito sull'ambiente host macOS.",
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
                
                // Card 2: Controlli Preflight & Parametri di Analisi
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("2. Preflight e Parametri di Analisi")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Theme.textPrimary)
                        Spacer()
                        telemetryModeSelector
                    }
                    
                    if telemetryInputMode == 0 {
                        fixtureParametersView
                    } else {
                        guestTelemetryParametersView
                    }
                    
                    // Mostra esito preflight
                    if let preflight = appState.preflightResult {
                        switch preflight {
                        case .passed:
                            BannerAlertView(
                                title: "Preflight Superato",
                                message: "Tutti i requisiti di isolamento e stato VM risultano conformi. Analisi autorizzata.",
                                level: .info
                            )
                        case .failed(let reasons):
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Avvio Bloccato dai Controlli Preflight (Fail-Closed):")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(Theme.criticalRed)
                                ForEach(reasons, id: \.self) { r in
                                    HStack(spacing: 6) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 10))
                                            .foregroundColor(Theme.criticalRed)
                                        Text(r)
                                            .font(.system(size: 11))
                                            .foregroundColor(Theme.textPrimary)
                                    }
                                }
                            }
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Theme.criticalRedSubtle)
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Theme.criticalRed.opacity(0.4), lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(16)
                .background(Theme.surfaceCard)
                .cornerRadius(Theme.cardCornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                        .stroke(Theme.borderDefault, lineWidth: 1)
                )
                
                // Card 3: Monitoraggio e Timer in Tempo Reale
                if securityEngine.isAnalysisActive || securityEngine.activeAnalysisState == .completed || securityEngine.activeAnalysisState == .stopped {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("3. Monitoraggio della Sessione")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(Theme.textPrimary)
                            Spacer()
                            
                            HStack(spacing: 8) {
                                Text("Tempo trascorso: \(securityEngine.elapsedTimeSeconds)s")
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(Theme.accentTealBright)
                                
                                StatusBadgeView(
                                    securityEngine.activeAnalysisState.rawValue,
                                    style: securityEngine.isAnalysisActive ? .manualReview : .verified
                                )
                            }
                        }
                        
                        ProgressView(value: securityEngine.analysisProgress, total: 1.0)
                            .accentColor(Theme.accentTeal)
                        
                        HStack {
                            Text("Stato Controller: In ascolto telemetria guest autorizzato")
                                .font(.system(size: 11))
                                .foregroundColor(Theme.textMuted)
                            Spacer()
                            Text("\(Int(securityEngine.analysisProgress * 100))% completato")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Theme.textSecondary)
                        }
                    }
                    .padding(16)
                    .background(Theme.surfaceCard)
                    .cornerRadius(Theme.cardCornerRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                            .stroke(Theme.borderDefault, lineWidth: 1)
                    )
                }
                
                // Card 4: Report Finale dei Risultati
                if let report = securityEngine.currentReport {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 8) {
                                    Image(systemName: report.classification.icon)
                                        .font(.system(size: 22))
                                        .foregroundColor(report.classification == .detected ? Theme.criticalRed : (report.classification == .suspicious ? Theme.warningAmber : Theme.accentTealBright))
                                    
                                    Text("Esito Analisi: \(report.classification.rawValue)")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(Theme.textPrimary)
                                }
                                
                                Text(report.summary)
                                    .font(.system(size: 12))
                                    .foregroundColor(Theme.textSecondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Livello Confidenza")
                                    .font(.system(size: 10))
                                    .foregroundColor(Theme.textMuted)
                                Text("\(Int(report.confidenceScore * 100))%")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(Theme.accentTealBright)
                            }
                        }
                        
                        Divider().background(Theme.borderSubtle)
                        
                        // Evidenze osservate
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Evidenze Osservate:")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Theme.textPrimary)
                            
                            ForEach(report.evidence, id: \.self) { ev in
                                HStack(alignment: .top, spacing: 6) {
                                    Text("•")
                                        .foregroundColor(Theme.accentTeal)
                                    Text(ev)
                                        .font(.system(size: 12))
                                        .foregroundColor(Theme.textSecondary)
                                }
                            }
                        }
                        
                        // Regole attivate
                        if !report.rulesTriggered.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Regole Deterministiche Attivate:")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(Theme.textPrimary)
                                
                                ForEach(report.rulesTriggered) { rule in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("[\(rule.id)] \(rule.ruleName)")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(Theme.textPrimary)
                                            Text(rule.description)
                                                .font(.system(size: 11))
                                                .foregroundColor(Theme.textSecondary)
                                        }
                                        Spacer()
                                        StatusBadgeView(rule.severity.rawValue, style: rule.severity == .critical ? .critical : .manualReview)
                                    }
                                    .padding(8)
                                    .background(Theme.surfaceElevated.opacity(0.5))
                                    .cornerRadius(4)
                                }
                            }
                        }
                        
                        // Azioni di contenimento
                        if !report.actionsExecuted.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Azioni di Contenimento Eseguite:")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(Theme.textPrimary)
                                
                                ForEach(report.actionsExecuted) { act in
                                    HStack {
                                        Image(systemName: "hand.raised.fill")
                                            .foregroundColor(Theme.warningAmber)
                                        Text(act.actionType)
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(Theme.textPrimary)
                                        Spacer()
                                        Text(act.status)
                                            .font(.system(size: 11))
                                            .foregroundColor(Theme.textMuted)
                                    }
                                    .padding(8)
                                    .background(Theme.bgDeep)
                                    .cornerRadius(4)
                                }
                            }
                        }
                        
                        // Limiti noti dell'analisi
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Limiti dell'Analisi (Dichiarazione Esplicita):")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Theme.textMuted)
                            ForEach(report.limitations, id: \.self) { lim in
                                Text("– \(lim)")
                                    .font(.system(size: 10))
                                    .foregroundColor(Theme.textMuted)
                            }
                        }
                    }
                    .padding(16)
                    .background(Theme.surfaceCard)
                    .cornerRadius(Theme.cardCornerRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                            .stroke(Theme.accentTeal.opacity(0.4), lineWidth: 1)
                    )
                }
            }
            .padding(24)
        }
        .background(Theme.bgDeep)
    }
    
    // MARK: - Subviews per Card 2 (Preflight e Parametri)
    
    @ViewBuilder
    private var telemetryModeSelector: some View {
        Picker("", selection: $telemetryInputMode) {
            Text("Fixture Sintetica (v0.3)").tag(0)
            Text("Telemetria Guest .jsonl (v0.5)").tag(1)
        }
        .labelsHidden()
        .pickerStyle(.segmented)
        .frame(width: 320)
        .onChange(of: telemetryInputMode) {
            appState.isUsingRealTelemetry = (telemetryInputMode == 1)
        }
    }
    
    @ViewBuilder
    private var fixtureParametersView: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Scenario dimostrativo fixture:")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textMuted)
                
                Picker("", selection: $appState.selectedScenario) {
                    ForEach(SecurityEngine.SimulatedScenario.allCases) { sc in
                        Text(sc.rawValue).tag(sc)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(maxWidth: 260)
            }
            
            Spacer()
            
            Button(action: {
                handleStartAnalysis()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "play.shield.fill")
                    Text("Verifica Preflight e Avvia Analisi")
                }
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Theme.bgDeep)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(appState.targetFile != nil ? Theme.accentTealBright : Theme.textMuted)
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
            .disabled(appState.targetFile == nil || securityEngine.isAnalysisActive)
        }
    }
    
    @ViewBuilder
    private var guestTelemetryParametersView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Button(action: {
                    openTelemetryFilePicker()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.down.fill")
                        Text("Importa file .jsonl...")
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Theme.surfaceElevated)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    loadGuestSensorSimulationStream()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.badge.clock.fill")
                        Text("Carica Stream Dimostrativo Sensore Guest")
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Theme.accentTealBright)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Theme.accentTealSubtle)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button(action: {
                    handleStartAnalysis()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "play.shield.fill")
                        Text("Avvia Analisi Telemetria Guest")
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Theme.bgDeep)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(isGuestAnalysisReady ? Theme.accentTealBright : Theme.textMuted)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .disabled(!isGuestAnalysisReady || securityEngine.isAnalysisActive)
            }
            
            if let result = appState.importedTelemetryResult {
                HStack(spacing: 12) {
                    StatusBadgeView("\(result.validEventsCount) eventi validati", style: .verified)
                    if result.corruptedLinesCount > 0 {
                        StatusBadgeView("\(result.corruptedLinesCount) righe scartate", style: .manualReview)
                    }
                    Text("Regole attivate: \(result.ruleMatches.count)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                    Spacer()
                    Text("Classificazione: \(result.classification.rawValue)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(result.classification == .detected ? Theme.criticalRed : Theme.accentTealBright)
                }
                .padding(8)
                .background(Theme.bgDeep)
                .cornerRadius(6)
            } else {
                Text("Nessun file di telemetria caricato. Importa un file generato da 'sentinel_guest_sensor.py' o usa lo stream dimostrativo.")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textMuted)
            }
        }
    }
    
    private var isGuestAnalysisReady: Bool {
        appState.targetFile != nil && appState.importedTelemetryResult != nil
    }
    
    private func handleStartAnalysis() {
        let isPreflightOk = appState.performPreflight()
        if isPreflightOk {
            if appState.isUsingRealTelemetry && appState.importedTelemetryResult != nil {
                appState.startRealTelemetryAnalysis()
            } else {
                appState.startAnalysis(scenario: appState.selectedScenario)
            }
        }
    }
    
    private func openTelemetryFilePicker() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.message = "Seleziona file di telemetria generato dal sensore guest (.jsonl)"
        
        if panel.runModal() == .OK, let url = panel.url {
            appState.importGuestTelemetry(from: url)
        }
    }
    
    private func loadGuestSensorSimulationStream() {
        // Genera stream con tutti gli eventi del sensore guest (child proc + burst /tmp + network egress + persistence)
        let events = FixtureDatasets.makeAllScenariosChain()
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        var lines: [String] = []
        for ev in events {
            if let data = try? encoder.encode(ev), let str = String(data: data, encoding: .utf8) {
                lines.append(str)
            }
        }
        let jsonl = lines.joined(separator: "\n")
        appState.importGuestTelemetry(jsonlText: jsonl, sourceDescription: "Simulazione Completa Sensore Guest (v0.5)")
    }
    
    private func openNativeFilePicker() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.message = "Seleziona un file da analizzare (Nessun file verrà eseguito sull'host)"
        
        if panel.runModal() == .OK, let url = panel.url {
            appState.selectFile(url: url)
        }
    }
    
    private func loadMockFixtureFile(name: String) {
        // Crea o carica un file temporaneo sicuro per dimostrare il calcolo di SHA256
        let tempDir = FileManager.default.temporaryDirectory
        let sampleURL = tempDir.appendingPathComponent(name)
        let sampleContent = "SentinelAI fixture mock payload: \(UUID().uuidString)\nGenerated for safe demonstration.\n"
        try? sampleContent.write(to: sampleURL, atomically: true, encoding: .utf8)
        appState.selectFile(url: sampleURL)
    }
}
