import SwiftUI

public struct StatusBadgeView: View {
    public let text: String
    public let icon: String?
    public let style: BadgeStyle
    
    public enum BadgeStyle {
        case verified
        case manualReview
        case notConfigured
        case critical
        case neutral
        case classification(AnalysisClassification)
    }
    
    public init(_ text: String, icon: String? = nil, style: BadgeStyle = .neutral) {
        self.text = text
        self.icon = icon
        self.style = style
    }
    
    private var foregroundColor: Color {
        switch style {
        case .verified:
            return Theme.accentTealBright
        case .manualReview:
            return Theme.warningAmber
        case .notConfigured:
            return Theme.textSecondary
        case .critical:
            return Theme.criticalRed
        case .neutral:
            return Theme.textPrimary
        case .classification(let c):
            switch c {
            case .detected: return Theme.criticalRed
            case .suspicious: return Theme.warningAmber
            case .notDetected: return Theme.accentTealBright
            case .unverifiable: return Theme.statusInfo
            }
        }
    }
    
    private var backgroundColor: Color {
        switch style {
        case .verified:
            return Theme.accentTealSubtle
        case .manualReview:
            return Theme.warningAmberSubtle
        case .notConfigured:
            return Theme.borderSubtle
        case .critical:
            return Theme.criticalRedSubtle
        case .neutral:
            return Theme.surfaceElevated
        case .classification(let c):
            switch c {
            case .detected: return Theme.criticalRedSubtle
            case .suspicious: return Theme.warningAmberSubtle
            case .notDetected: return Theme.accentTealSubtle
            case .unverifiable: return Theme.statusInfoSubtle
            }
        }
    }
    
    private var borderColor: Color {
        foregroundColor.opacity(0.3)
    }
    
    public var body: some View {
        HStack(spacing: 5) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
            }
            Text(text)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundColor(foregroundColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(backgroundColor)
        .cornerRadius(5)
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(borderColor, lineWidth: 1)
        )
    }
}
