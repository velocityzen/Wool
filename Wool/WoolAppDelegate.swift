import AppKit
import SwiftUI

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

  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false
  }

  func toggleScreenAndKeyboardLock(_ state: Bool? = nil) {
    guard let wool = self.wool else { return }
    
    if let state = state {
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
    
    if let state = state {
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
    if let lockWindow = self.window {
      lockWindow.makeKeyAndOrderFront(self)
      lockWindow.toggleFullScreen(self)
    } else {
      createLockWindow()
    }
  }

  private func hideLockScreenWindow() {
    if let lockWindow = self.window {
      lockWindow.close()
    }
  }

  private func createLockWindow() {
    guard let screen = NSScreen.main else { return }
    let screenFrame = screen.frame

    let lockWindow = NSWindow(
      contentRect: screenFrame,
      styleMask: [.borderless],
      backing: .buffered,
      defer: false,
      screen: NSScreen.main
    )

//    lockWindow.center()
    lockWindow.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    lockWindow.isOpaque = true
    lockWindow.level = .mainMenu + 1
//    lockWindow.title = "Lock for \(screen.localizedName)"
    lockWindow.isReleasedWhenClosed = false
    
    lockWindow.contentView = NSHostingView(rootView: LockScreenView(screenName: screen.localizedName))
    lockWindow.makeKeyAndOrderFront(nil)
//    lockWindow.toggleFullScreen(self)

    self.window = lockWindow
  }

  private func lockKeyboard () {
    if let eventTap = self.eventTap {
      CGEvent.tapEnable(tap: eventTap, enable: true)
    } else {
      setupEventTap()
    }
  }

  private func unlockKeyboard () {
    if let eventTap = self.eventTap {
      CGEvent.tapEnable(tap: eventTap, enable: false)
    }
  }

  private func setupEventTap() {
    let eventMask = (1 << CGEventType.keyDown.rawValue)

    guard let eventTap = CGEvent.tapCreate(
      tap: .cghidEventTap,
      place: .headInsertEventTap,
      options: .defaultTap,
      eventsOfInterest: CGEventMask(eventMask),
      callback: blockAllEvents,
      userInfo: nil
    ) else {
      print("Failed to create event tap. Check system preferences for accessibility settings.")
      return quit()
    }

    self.eventTap = eventTap

    runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
    CGEvent.tapEnable(tap: eventTap, enable: true)
    CFRunLoopRun()
  }

  private func destroyEventTap() {
    if let source = runLoopSource {
      CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
    }

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


func blockAllEvents(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, refcon: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
  return nil
}

func pathToBool(_ path: String?) -> Bool? {
  guard let path = path else {
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
