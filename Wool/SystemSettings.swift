import AppKit

enum SystemSettingsPane: String {
  case privacyAccessibility = "com.apple.preference.security?Privacy_Accessibility"

  var url: URL {
    return URL(string: "x-apple.systempreferences:\(self.rawValue)")!
  }
}

func openSystemSettings(_ pane: SystemSettingsPane) {
  NSWorkspace.shared.open(pane.url)
}
