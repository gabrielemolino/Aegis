import SwiftUI

public struct SecurityChecklistRow: View {
    public let title: String
    public let detail: String
    public let isVerified: Bool
    public let isManualCheckRequired: Bool
    public let toggleAction: (() -> Void)?
    
    public init(
        title: String,
        detail: String,
        isVerified: Bool,
        isManualCheckRequired: Bool = false,
        toggleAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.detail = detail
        self.isVerified = isVerified
        self.isManualCheckRequired = isManualCheckRequired
        self.toggleAction = toggleAction
    }
    
    public var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: isVerified ? "checkmark.shield.fill" : (isManualCheckRequired ? "exclamationmark.shield.fill" : "xmark.shield.fill"))
                .font(.system(size: 16))
                .foregroundColor(isVerified ? Theme.accentTealBright : (isManualCheckRequired ? Theme.warningAmber : Theme.criticalRed))
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                
                Text(detail)
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textSecondary)
            }
            
            Spacer()
            
            if isVerified {
                StatusBadgeView("Conforme", icon: "checkmark", style: .verified)
            } else if isManualCheckRequired {
                if let toggleAction = toggleAction {
                    Button(action: toggleAction) {
                        StatusBadgeView("Verifica manuale richiesta", icon: "hand.tap", style: .manualReview)
                    }
                    .buttonStyle(.plain)
                    .help("Clicca per confermare la verifica manuale dei parametri VM")
                } else {
                    StatusBadgeView("Verifica manuale richiesta", icon: "questionmark", style: .manualReview)
                }
            } else {
                StatusBadgeView("Non conforme", icon: "exclamationmark.triangle", style: .critical)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(Theme.surfaceElevated.opacity(0.4))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Theme.borderSubtle, lineWidth: 1)
        )
    }
}
