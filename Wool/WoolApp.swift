import SwiftUI

@Observable class Wool {
  var isScreenLockEnabled: Bool = false
  var isKeyboardLockEnabled: Bool = false
  var hasPermission: Bool = false
}

@main
struct WoolApp: App {
  @NSApplicationDelegateAdaptor(WoolAppDelegate.self) var appDelegate
  @State private var wool: Wool = .init()

  init() {
    appDelegate.wool = wool
  }

  var body: some Scene {
    MenuBarExtra("Wool", systemImage: getMenuBarIcon()) {
      Button(action: toggleScreenAndKeyboardLock) {
        Label(
          "\(getLockLabel(wool.isScreenLockEnabled)) Screen & Keyboard",
          systemImage: "lock"
        )
        .labelStyle(.titleAndIcon)
      }
      .keyboardShortcut("S")
      .disabled(!wool.hasPermission)

      Button(action: toggleKeyboardLock) {
        Label(
          "\(getLockLabel(wool.isKeyboardLockEnabled)) Keyboard",
          systemImage: "keyboard"
        )
        .labelStyle(.titleAndIcon)
      }
      .keyboardShortcut("K")
      .disabled(!wool.hasPermission)

      Divider()

      if !wool.hasPermission {
        Button(action: openAccessibilitySettings) {
          Label(
            "Open Security & Privacy > Accessibility > Keyboard",
            systemImage: "exclamationmark.triangle"
          )
          .labelStyle(.titleAndIcon)
        }

        Divider()
      }

      Button("Quit") {
        quit()
      }
      .keyboardShortcut("Q")
    }
  }

  func getMenuBarIcon() -> String {
    if wool.isScreenLockEnabled || wool.isKeyboardLockEnabled {
      return "bubbles.and.sparkles.fill"
    }

    return "bubbles.and.sparkles"
  }

  func getLockLabel(_ isLocked: Bool) -> String {
    return isLocked ? "Unlock" : "Lock"
  }

  func toggleScreenAndKeyboardLock() {
    appDelegate.toggleScreenAndKeyboardLock()
  }

  func toggleKeyboardLock() {
    appDelegate.toggleKeyboardLock()
  }

  func openAccessibilitySettings() {
    openSystemSettings(.privacyAccessibility)
    appDelegate.trySetupEventTapUntilSuccess()
  }

  func quit() {
    NSApplication.shared.terminate(nil)
  }
}
