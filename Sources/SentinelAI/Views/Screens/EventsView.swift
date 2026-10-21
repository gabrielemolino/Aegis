import SwiftUI
import AppKit

public struct EventsView: View {
    @ObservedObject var appState: AppState
    @ObservedObject private var auditLogger = AuditLogger.shared
    
    @State private var selectedCategory: AuditCategory = .all
    @State private var searchText: String = ""
    @State private var exportNotificationMessage: String? = nil
    @State private var showRuleCatalogSheet: Bool = false
    
    public init(appState: AppState) {
        self.appState = appState
    }
    
    private var filteredEvents: [AuditEvent] {
        auditLogger.events.filter { event in
            let matchesCategory = (selectedCategory == .all) || (event.category == selectedCategory)
            let matchesSearch = searchText.isEmpty ||
                event.description.localizedCaseInsensitiveContains(searchText) ||
                event.source.localizedCaseInsensitiveContains(searchText) ||
                (event.details?.localizedCaseInsensitiveContains(searchText) ?? false)
            return matchesCategory && matchesSearch
        }
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Audit Log ed Eventi")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                    Text("Tracciamento immutabile di tutti i controlli, preflight e azioni di contenimento.")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                }
                Spacer()
                
                HStack(spacing: 8) {
                    Button(action: {
                        showRuleCatalogSheet = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "bolt.shield.fill")
                            Text("Catalogo & Fixture")
                        }
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Theme.accentTealBright)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Theme.accentTealSubtle)
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        copyLogToClipboard()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "doc.on.doc")
                            Text("Copia Testo")
                        }
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Theme.textPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Theme.surfaceElevated)
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        exportLogToFile()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.up")
                            Text("Esporta JSON")
                        }
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Theme.bgDeep)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Theme.accentTealBright)
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            
            // Search and Filter Bar
            HStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Theme.textMuted)
                    TextField("Cerca negli eventi o sorgenti...", text: $searchText)
                        .textFieldStyle(.plain)
                        .foregroundColor(Theme.textPrimary)
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(Theme.textMuted)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Theme.surfaceCard)
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Theme.borderDefault, lineWidth: 1)
                )
                
                Picker("Categoria", selection: $selectedCategory) {
                    ForEach(AuditCategory.allCases, id: \.self) { cat in
                        Text(cat.rawValue).tag(cat)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 190)
            }
            .padding(.horizontal, 24)
            
            if let msg = exportNotificationMessage {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Theme.accentTealBright)
                    Text(msg)
                        .font(.system(size: 11))
                        .foregroundColor(Theme.textPrimary)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Theme.accentTealSubtle)
                .cornerRadius(4)
                .padding(.horizontal, 24)
            }
            
            // Events Table / List
            ScrollView {
                LazyVStack(spacing: 8) {
                    if filteredEvents.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.system(size: 28))
                                .foregroundColor(Theme.textMuted)
                            Text("Nessun evento corrispondente ai filtri")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        ForEach(filteredEvents) { ev in
                            HStack(alignment: .top, spacing: 12) {
                                // Severity indicator icon
                                Image(systemName: ev.level == .critical ? "exclamationmark.octagon.fill" : (ev.level == .warning ? "exclamationmark.triangle.fill" : "info.circle.fill"))
                                    .font(.system(size: 14))
                                    .foregroundColor(ev.level == .critical ? Theme.criticalRed : (ev.level == .warning ? Theme.warningAmber : Theme.statusInfo))
                                    .padding(.top, 2)
                                
                                VStack(alignment: .leading, spacing: 3) {
                                    HStack(spacing: 8) {
                                        Text(ev.formattedTimestamp)
                                            .font(.system(size: 10, design: .monospaced))
                                            .foregroundColor(Theme.textMuted)
                                        
                                        Text("[\(ev.source)]")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(Theme.accentTeal)
                                        
                                        StatusBadgeView(ev.category.rawValue, style: .neutral)
                                        
                                        if ev.isSimulation {
                                            StatusBadgeView("Simulazione", style: .manualReview)
                                        }
                                    }
                                    
                                    Text(ev.description)
                                        .font(.system(size: 12))
                                        .foregroundColor(Theme.textPrimary)
                                    
                                    if let details = ev.details, !details.isEmpty {
                                        Text(details)
                                            .font(.system(size: 11, design: .monospaced))
                                            .foregroundColor(Theme.textSecondary)
                                            .padding(6)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(Theme.bgDeep)
                                            .cornerRadius(4)
                                    }
                                }
                                
                                Spacer()
                            }
                            .padding(10)
                            .background(Theme.surfaceCard)
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Theme.borderSubtle, lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .background(Theme.bgDeep)
        .sheet(isPresented: $showRuleCatalogSheet) {
            RuleCatalogView(appState: appState)
        }
    }
    
    private func copyLogToClipboard() {
        let text = auditLogger.exportAsText()
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        withAnimation {
            exportNotificationMessage = "Log copiato negli appunti con successo."
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            exportNotificationMessage = nil
        }
    }
    
    private func exportLogToFile() {
        let json = auditLogger.exportAsJSON()
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.json]
        savePanel.nameFieldStringValue = "sentinelai_audit_\(Int(Date().timeIntervalSince1970)).json"
        
        if savePanel.runModal() == .OK, let url = savePanel.url {
            try? json.write(to: url, atomically: true, encoding: .utf8)
            withAnimation {
                exportNotificationMessage = "Report salvato in: \(url.lastPathComponent)"
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                exportNotificationMessage = nil
            }
        }
    }
}
