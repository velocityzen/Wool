import AppKit
import SwiftUI

let ANSI_S: CGKeyCode = 0x01

class WoolAppDelegate: NSObject, NSApplicationDelegate {
  var window: NSWindow?
  var eventTap: CFMachPort?
  var runLoopSource: CFRunLoopSource?

  weak var wool: Wool?

  func application(_ application: NSApplication, open urls: [URL]) {
    for url in urls {
      switch url.host {
      case "toggle-lock":
        toggleScreenAndKeyboardLock(pathToBool(url.path))

      case "toggle-keyboard-lock":
        toggleKeyboardLock(pathToBool(url.path))

      default:
        return
      }
    }
  }

  func applicationDidFinishLaunching(_ notification: Notification) {
    // nothin, absolutly nothin
  }

  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication)
    -> Bool
  {
    return false
  }

  func toggleScreenAndKeyboardLock(_ state: Bool? = nil) {
    guard let wool = self.wool else { return }

    if let state {
      wool.isScreenLockEnabled = state
    } else {
      wool.isScreenLockEnabled.toggle()
    }

    if wool.isScreenLockEnabled {
      wool.isKeyboardLockEnabled = true
      showLockScreenWindow()
      lockKeyboard()
    } else {
      wool.isKeyboardLockEnabled = false
      hideLockScreenWindow()
      unlockKeyboard()
    }
  }

  func toggleKeyboardLock(_ state: Bool? = nil) {
    guard let wool = self.wool else { return }

    if let state {
      wool.isKeyboardLockEnabled = state
    } else {
      wool.isKeyboardLockEnabled.toggle()
    }

    if wool.isKeyboardLockEnabled {
      lockKeyboard()
    } else {
      unlockKeyboard()
    }
  }

  private func showLockScreenWindow() {
    if let window {
      window.makeKeyAndOrderFront(self)
      window.toggleFullScreen(self)
    } else {
      createLockWindow()
    }
  }

  private func hideLockScreenWindow() {
    if let window {
      window.close()
    }
  }

  private func createLockWindow() {
    guard let screen = NSScreen.main else { return }
    let screenFrame = screen.frame

    let window = NSWindow(
      contentRect: screenFrame,
      styleMask: [.borderless],
      backing: .buffered,
      defer: false,
      screen: NSScreen.main
    )

    window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    window.isOpaque = true
    window.level = .mainMenu + 1
    window.title = "Lock for \(screen.localizedName)"
    window.isReleasedWhenClosed = false

    window.contentView = NSHostingView(
      rootView: LockScreenView(screenName: screen.localizedName)
    )
    window.orderFront(nil)

    self.window = window
  }

  private func lockKeyboard() {
    if let eventTap {
      CGEvent.tapEnable(tap: eventTap, enable: true)
    } else {
      setupEventTap()
    }
  }

  private func unlockKeyboard() {
    if let eventTap {
      CGEvent.tapEnable(tap: eventTap, enable: false)
    }
  }

  private func setupEventTap() {
    let eventMask = (1 << CGEventType.keyDown.rawValue)
    let refcon = UnsafeMutableRawPointer(
      Unmanaged.passUnretained(self).toOpaque()
    )

    guard
      let eventTap = CGEvent.tapCreate(
        tap: .cghidEventTap,
        place: .headInsertEventTap,
        options: .defaultTap,
        eventsOfInterest: CGEventMask(eventMask),
        callback: eventTapCallback,
        userInfo: refcon
      )
    else {
      print(
        "Failed to create event tap. Check system preferences for accessibility settings."
      )
      return quit()
    }

    self.eventTap = eventTap

    runLoopSource = CFMachPortCreateRunLoopSource(
      kCFAllocatorDefault,
      eventTap,
      0
    )
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
    CGEvent.tapEnable(tap: eventTap, enable: true)
    CFRunLoopRun()
  }

  private func destroyEventTap() {
    if let source = runLoopSource {
      CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
    }

  }

  func onKeyDown(event: CGEvent) -> Unmanaged<CGEvent>? {
    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
    let flags = event.flags

    let isCommand = flags.contains(.maskCommand)
    let isShift = flags.contains(.maskShift)

    if keyCode == ANSI_S && isCommand && isShift {
      toggleScreenAndKeyboardLock(false)
    }

    return nil
  }

  func applicationWillTerminate(_ notification: Notification) {
    unlockKeyboard()
    destroyEventTap()
  }

  func quit() {
    NSApplication.shared.terminate(self)
  }

  deinit {
    destroyEventTap()
  }
}

private func eventTapCallback(
  proxy: CGEventTapProxy,
  type: CGEventType,
  event: CGEvent,
  userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
  if type == .keyDown {
    if let userInfo {
      let delegate = Unmanaged<WoolAppDelegate>.fromOpaque(userInfo)
        .takeUnretainedValue()
      return delegate.onKeyDown(event: event)
    }
  }

  return Unmanaged.passUnretained(event)
}

func pathToBool(_ path: String?) -> Bool? {
  guard let path else {
    return nil
  }

  switch path.replacingOccurrences(of: "/", with: "").lowercased() {
  case "true", "yes", "on", "1":
    return true
  case "false", "no", "off", "0":
    return false
  default:
    return nil
  }
}
