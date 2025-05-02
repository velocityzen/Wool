import SwiftUI

@Observable class Wool {
  var isScreenLockEnabled: Bool = false
  var isKeyboardLockEnabled: Bool = false
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
        Label("\(getLockLabel(wool.isScreenLockEnabled)) Screen & Keyboard", systemImage: "lock")
          .labelStyle(.titleAndIcon)
      }
      .keyboardShortcut("S")

      Button(action: toggleKeyboardLock) {
        Label("\(getLockLabel(wool.isKeyboardLockEnabled)) Keyboard", systemImage: "keyboard")
          .labelStyle(.titleAndIcon)
      }
      .keyboardShortcut("K")

      Divider()

      Button("Quit") {
        quit()
      }
      .keyboardShortcut("Q")
    }
  }

  func getMenuBarIcon() -> String {
    if (wool.isScreenLockEnabled || wool.isKeyboardLockEnabled) {
      return "bubbles.and.sparkles.fill"
    }

    return "bubbles.and.sparkles"
  }

  func getLockLabel(_ isLocked: Bool) -> String {
    return isLocked ? "Unlock" : "Lock";
  }

  func toggleScreenAndKeyboardLock() {
    appDelegate.toggleScreenAndKeyboardLock()
  }

  func toggleKeyboardLock() {
    appDelegate.toggleKeyboardLock()
  }

  func quit() {
    NSApplication.shared.terminate(nil)
  }
}


