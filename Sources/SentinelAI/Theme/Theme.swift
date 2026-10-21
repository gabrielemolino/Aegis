import SwiftUI

public struct Theme {
    public static let bgDeep = Color(red: 0.043, green: 0.059, blue: 0.090)       // #0B0F17
    public static let bgSidebar = Color(red: 0.055, green: 0.078, blue: 0.125)    // #0E1420
    public static let surfaceCard = Color(red: 0.082, green: 0.114, blue: 0.165)  // #151D2A
    public static let surfaceElevated = Color(red: 0.110, green: 0.149, blue: 0.220) // #1C2638
    
    public static let borderDefault = Color(red: 0.149, green: 0.204, blue: 0.290) // #26344A
    public static let borderSubtle = Color(red: 0.118, green: 0.161, blue: 0.231)  // #1E293B
    
    public static let accentTeal = Color(red: 0.110, green: 0.760, blue: 0.686)    // #1CC2AF
    public static let accentTealBright = Color(red: 0.250, green: 0.880, blue: 0.810)
    public static let accentTealSubtle = Color(red: 0.110, green: 0.760, blue: 0.686).opacity(0.12)
    
    public static let warningAmber = Color(red: 0.961, green: 0.620, blue: 0.180)  // #F59E0B
    public static let warningAmberSubtle = Color(red: 0.961, green: 0.620, blue: 0.180).opacity(0.12)
    
    // Il rosso è riservato ESCLUSIVAMENTE ad avvisi critici
    public static let criticalRed = Color(red: 0.937, green: 0.267, blue: 0.267)   // #EF4444
    public static let criticalRedSubtle = Color(red: 0.937, green: 0.267, blue: 0.267).opacity(0.12)
    
    public static let statusInfo = Color(red: 0.220, green: 0.580, blue: 0.860)    // #3894DC
    public static let statusInfoSubtle = Color(red: 0.220, green: 0.580, blue: 0.860).opacity(0.12)
    
    public static let textPrimary = Color(white: 0.96)
    public static let textSecondary = Color(white: 0.70)
    public static let textMuted = Color(white: 0.46)
    
    public static let standardCornerRadius: CGFloat = 8.0
    public static let cardCornerRadius: CGFloat = 10.0
}
