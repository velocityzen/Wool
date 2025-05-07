import AppKit
import SwiftUI

let ANSI_S: CGKeyCode = 0x01

class WoolAppDelegate: NSObject, NSApplicationDelegate {
  var window: NSWindow?
  var eventTap: CFMachPort?
  var runLoopSource: CFRunLoopSource?

  var hasApplicationDidFinishLaunching: Bool = false
  var pendingDeepLink: URL?
  
  weak var wool: Wool?

  func application(_ application: NSApplication, open urls: [URL]) {
    if !hasApplicationDidFinishLaunching {
      pendingDeepLink = urls.first
      return
    }
    
    for url in urls {
      handleDeepLink(url)
    }
  }

  func applicationDidFinishLaunching(_ notification: Notification) {
    hasApplicationDidFinishLaunching = true
    
    guard let wool else { return }
    wool.hasPermission = checkAccessibilitySettings()
    
    if let pendingDeepLink {
      handleDeepLink(pendingDeepLink)
      self.pendingDeepLink = nil
    }
  }

  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication)
    -> Bool {
    return false
  }
  
  func handleDeepLink(_ url: URL) {
    switch url.host {
      case "toggle-lock":
        toggleScreenAndKeyboardLock(pathToBool(url.path))
        
      case "toggle-keyboard-lock":
        toggleKeyboardLock(pathToBool(url.path))
        
      default:
        return
    }
  }

  func toggleScreenAndKeyboardLock(_ state: Bool? = nil) {
    guard let wool else { return }

    if !wool.hasPermission {
      return
    }

    let state = state ?? !wool.isScreenLockEnabled

    if state {
      toggleKeyboardLock(true)

      // toggle keyboard can trigger permissions
      if !wool.hasPermission {
        return
      }

      showLockScreenWindow()
    } else {
      toggleKeyboardLock(false)
      hideLockScreenWindow()
    }

    wool.isScreenLockEnabled = state
  }

  func toggleKeyboardLock(_ state: Bool? = nil) {
    guard let wool else { return }

    if !wool.hasPermission {
      return
    }

    let state = state ?? !wool.isKeyboardLockEnabled

    if state {
      if !lockKeyboard() {
        return
      }
    } else {
      unlockKeyboard()
    }

    wool.isKeyboardLockEnabled = state
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

  private func lockKeyboard() -> Bool {
    if let eventTap {
      CGEvent.tapEnable(tap: eventTap, enable: true)
      return true
    }

    return setupEventTap()
  }

  private func unlockKeyboard() {
    if let eventTap {
      CGEvent.tapEnable(tap: eventTap, enable: false)
    }
  }

  private func checkAccessibilitySettings() -> Bool {
    if CGPreflightListenEventAccess() {
      return true
    }

    if CGRequestListenEventAccess() {
      return true
    }

    print("No accessibility settings access granted.")
    return false
  }

  private func setupEventTap() -> Bool {
    let eventMask = (1 << CGEventType.keyDown.rawValue)
    let refcon = Unmanaged.passRetained(self)

    guard
      let eventTap = CGEvent.tapCreate(
        tap: .cghidEventTap,
        place: .headInsertEventTap,
        options: .defaultTap,
        eventsOfInterest: CGEventMask(eventMask),
        callback: eventTapCallback,
        userInfo: refcon.toOpaque()
      )
    else {
      print(
        "Failed to create event tap. Check system preferences for accessibility settings."
      )

      wool?.hasPermission = false
      return false
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

    wool?.hasPermission = true

    return true
  }

  private func destroyEventTap() {
    if let source = runLoopSource {
      CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
    }
  }

  @MainActor
  func trySetupEventTap() async -> Bool {
    if !setupEventTap() {
      return false
    }

    if let eventTap {
      CGEvent.tapEnable(tap: eventTap, enable: false)
    }

    return true
  }

  func trySetupEventTapUntilSuccess(interval: TimeInterval = 2) {
    Task.detached { [self] in
      while true {
        if await trySetupEventTap() {
          print("User gives me permission to listen for keyboard events!")
          break
        } else {
          print("Waiting for user to give me permission to create an event tap in \(interval)s...")
          try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
        }
      }
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
