import SwiftUI

public struct BannerAlertView: View {
    public let title: String
    public let message: String
    public let level: AuditLogLevel
    
    public init(title: String, message: String, level: AuditLogLevel = .warning) {
        self.title = title
        self.message = message
        self.level = level
    }
    
    private var color: Color {
        switch level {
        case .info: return Theme.statusInfo
        case .warning: return Theme.warningAmber
        case .critical: return Theme.criticalRed
        }
    }
    
    private var bgColor: Color {
        switch level {
        case .info: return Theme.statusInfoSubtle
        case .warning: return Theme.warningAmberSubtle
        case .critical: return Theme.criticalRedSubtle
        }
    }
    
    private var icon: String {
        switch level {
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .critical: return "exclamationmark.octagon.fill"
        }
    }
    
    public var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)
                .padding(.top, 1)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(color)
                
                Text(message)
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(10)
        .background(bgColor)
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(color.opacity(0.35), lineWidth: 1)
        )
    }
}
