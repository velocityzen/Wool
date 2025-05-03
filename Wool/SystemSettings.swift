import AppKit

enum SystemSettingsPane: String {
//  case general = "com.apple.preference.general"
//  case accessibility = "com.apple.preference.universalaccess"
//  case securityPrivacy = "com.apple.preference.security"
  case privacyAccessibility = "com.apple.preference.security?Privacy_Accessibility"
//  case privacyFullDiskAccess = "com.apple.preference.security?Privacy_AllFiles"
//  case notifications = "com.apple.preference.notifications"
//  case displays = "com.apple.preference.displays"
//  case keyboard = "com.apple.preference.keyboard"
  
  var url: URL {
    return URL(string: "x-apple.systempreferences:\(self.rawValue)")!
  }
}

func openSystemSettings(_ pane: SystemSettingsPane) {
  NSWorkspace.shared.open(pane.url)
}
