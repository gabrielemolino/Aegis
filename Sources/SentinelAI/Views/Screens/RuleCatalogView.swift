import SwiftUI

public struct RuleCatalogView: View {
    @ObservedObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedFixture: FixtureOption = .tempBurst
    @State private var evaluationMatches: [RuleEvaluationMatch] = []
    @State private var evaluatedEvents: [TelemetryEvent] = []
    @State private var classificationResult: (classification: AnalysisClassification, confidence: Double, summary: String)? = nil
    
    private let ruleService = RuleEngineService.shared
    
    public enum FixtureOption: String, CaseIterable, Identifiable {
        case clean = "Software Innocuo (Clean)"
        case tempBurst = "Burst File I/O in /tmp (Sospetto)"
        case unexpectedChild = "Processo Figlio Inatteso (Sospetto)"
        case persistence = "Persistenza /etc/systemd (Critico)"
        case heartbeatLoss = "Heartbeat Assente (Non Verificabile)"
        case promptInjection = "Prompt Injection nei Log (Dato Puro)"
        
        public var id: String { rawValue }
    }
    
    public init(appState: AppState) {
        self.appState = appState
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Theme.accentTeal.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: "bolt.shield.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Theme.accentTealBright)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Catalogo Regole & Valutatore Fixture (v0.3)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                    Text("Motore deterministico versionato: \(ruleService.engineVersion) • Indipendente da LLM")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.textSecondary)
                }
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Theme.textMuted)
                }
                .buttonStyle(.plain)
            }
            .padding(18)
            .background(Theme.surfaceElevated)
            
            Divider().background(Theme.borderSubtle)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Sezione 1: Banco di Prova Fixture Sintetiche
                    VStack(alignment: .leading, spacing: 14) {
                        Text("1. Banco di Prova Fixture Comportamentali")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Theme.accentTealBright)
                        
                        Text("Seleziona uno scenario sintetico innocuo conforme alla Sezione 9 delle specifiche per verificare in tempo reale l'attivazione delle regole:")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.textSecondary)
                        
                        HStack(spacing: 12) {
                            Picker("Scenario Fixture", selection: $selectedFixture) {
                                ForEach(FixtureOption.allCases) { opt in
                                    Text(opt.rawValue).tag(opt)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: 320)
                            
                            Button(action: {
                                runFixtureEvaluation()
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "play.fill")
                                    Text("Esegui Valutazione Deterministica")
                                }
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Theme.bgDeep)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(Theme.accentTealBright)
                                .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        // Esito valutazione fixture
                        if let res = classificationResult {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    StatusBadgeView(res.classification.rawValue, style: .classification(res.classification))
                                    Text("Confidenza Deterministica: \(Int(res.confidence * 100))%")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(Theme.textPrimary)
                                    Spacer()
                                    Text("\(evaluatedEvents.count) eventi analizzati")
                                        .font(.system(size: 11))
                                        .foregroundColor(Theme.textMuted)
                                }
                                
                                Text(res.summary)
                                    .font(.system(size: 12))
                                    .foregroundColor(Theme.textSecondary)
                                
                                if !evaluationMatches.isEmpty {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Regole Attivate (con ID Evento associati):")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(Theme.textPrimary)
                                        
                                        ForEach(evaluationMatches) { match in
                                            VStack(alignment: .leading, spacing: 3) {
                                                HStack {
                                                    Text("[\(match.ruleId)] \(match.ruleName)")
                                                        .font(.system(size: 11, weight: .bold))
                                                        .foregroundColor(Theme.accentTealBright)
                                                    Spacer()
                                                    StatusBadgeView(match.severity.rawValue, style: match.severity == .critical ? .critical : .manualReview)
                                                }
                                                Text("Indicatore: \(match.matchedIndicator)")
                                                    .font(.system(size: 11))
                                                    .foregroundColor(Theme.textSecondary)
                                                Text("Azione Host: \(match.recommendedAction.userDescription)")
                                                    .font(.system(size: 10, weight: .medium))
                                                    .foregroundColor(Theme.warningAmber)
                                                Text("Eventi collegati: \(match.triggeredEventIDs.joined(separator: ", "))")
                                                    .font(.system(size: 9, design: .monospaced))
                                                    .foregroundColor(Theme.textMuted)
                                            }
                                            .padding(8)
                                            .background(Theme.surfaceElevated)
                                            .cornerRadius(6)
                                        }
                                    }
                                }
                            }
                            .padding(12)
                            .background(Theme.bgDeep)
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.accentTeal.opacity(0.3), lineWidth: 1))
                        }
                    }
                    .padding(14)
                    .background(Theme.surfaceCard)
                    .cornerRadius(Theme.cardCornerRadius)
                    .overlay(RoundedRectangle(cornerRadius: Theme.cardCornerRadius).stroke(Theme.borderDefault, lineWidth: 1))
                    
                    // Sezione 2: Catalogo Ufficiale Regole Integrate
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("2. Catalogo Ufficiale Regole Versionate (\(ruleService.rulesCatalog.count) Regole)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Theme.textPrimary)
                            Spacer()
                            StatusBadgeView("Versione \(ruleService.engineVersion)", style: .neutral)
                        }
                        
                        VStack(spacing: 8) {
                            ForEach(ruleService.rulesCatalog) { rule in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("[\(rule.id)] \(rule.name)")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(Theme.textPrimary)
                                        Spacer()
                                        StatusBadgeView(rule.category.rawValue, style: .neutral)
                                        StatusBadgeView(rule.severity.rawValue, style: rule.severity == .critical ? .critical : (rule.severity == .medium ? .manualReview : .verified))
                                    }
                                    
                                    Text(rule.description)
                                        .font(.system(size: 11))
                                        .foregroundColor(Theme.textSecondary)
                                    
                                    HStack {
                                        Image(systemName: "shield.righthalf.filled")
                                            .font(.system(size: 10))
                                            .foregroundColor(Theme.accentTeal)
                                        Text("Azione ammissibile: \(rule.recommendedAction.rawValue) — \(rule.recommendedAction.userDescription)")
                                            .font(.system(size: 10))
                                            .foregroundColor(Theme.textMuted)
                                    }
                                }
                                .padding(10)
                                .background(Theme.surfaceElevated.opacity(0.6))
                                .cornerRadius(6)
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.borderSubtle, lineWidth: 1))
                            }
                        }
                    }
                    .padding(14)
                    .background(Theme.surfaceCard)
                    .cornerRadius(Theme.cardCornerRadius)
                    .overlay(RoundedRectangle(cornerRadius: Theme.cardCornerRadius).stroke(Theme.borderDefault, lineWidth: 1))
                }
                .padding(20)
            }
        }
        .frame(width: 720, height: 620)
        .background(Theme.bgDeep)
        .onAppear {
            runFixtureEvaluation()
        }
    }
    
    private func runFixtureEvaluation() {
        let events: [TelemetryEvent]
        switch selectedFixture {
        case .clean:
            events = FixtureDatasets.makeCleanFixture()
        case .tempBurst:
            events = FixtureDatasets.makeTempBurstFixture()
        case .unexpectedChild:
            events = FixtureDatasets.makeUnexpectedChildProcessFixture()
        case .persistence:
            events = FixtureDatasets.makeCriticalPersistenceFixture()
        case .heartbeatLoss:
            events = FixtureDatasets.makeHeartbeatLossFixture()
        case .promptInjection:
            events = FixtureDatasets.makeHostilePromptInjectionFixture()
        }
        
        self.evaluatedEvents = events
        let matches = ruleService.evaluate(events: events)
        self.evaluationMatches = matches
        let classification = ruleService.classify(matches: matches)
        self.classificationResult = classification
    }
}
