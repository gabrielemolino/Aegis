import SwiftUI

public struct MetricCardView: View {
    public let title: String
    public let value: String
    public let detail: String
    public let icon: String
    public let badgeText: String?
    public let badgeStyle: StatusBadgeView.BadgeStyle
    public let actionTitle: String?
    public let action: (() -> Void)?
    
    public init(
        title: String,
        value: String,
        detail: String,
        icon: String,
        badgeText: String? = nil,
        badgeStyle: StatusBadgeView.BadgeStyle = .neutral,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.value = value
        self.detail = detail
        self.icon = icon
        self.badgeText = badgeText
        self.badgeStyle = badgeStyle
        self.actionTitle = actionTitle
        self.action = action
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.accentTeal)
                    Text(title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                }
                Spacer()
                if let badgeText = badgeText {
                    StatusBadgeView(badgeText, style: badgeStyle)
                }
            }
            
            Text(value)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(Theme.textPrimary)
            
            Text(detail)
                .font(.system(size: 11))
                .foregroundColor(Theme.textMuted)
                .lineLimit(2)
            
            if let actionTitle = actionTitle, let action = action {
                Spacer(minLength: 4)
                Button(action: action) {
                    Text(actionTitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Theme.accentTealBright)
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
            }
        }
        .padding(14)
        .background(Theme.surfaceCard)
        .cornerRadius(Theme.cardCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                .stroke(Theme.borderDefault, lineWidth: 1)
        )
    }
}
