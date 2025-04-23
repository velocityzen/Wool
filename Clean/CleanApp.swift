import SwiftUI

@main
struct CleanApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  
  @State private var isScreenLockEnabled: Bool = false
  @State private var isKeyboardLockEnabled: Bool = false
  
  var body: some Scene {
    MenuBarExtra("Clean", systemImage: getMenuBarIcon()) {
      Button(action: toggleScreenAndKeyboardLock) {
        Label("\(getLockLabel(isScreenLockEnabled)) Screen & Keyboard", systemImage: "lock")
          .labelStyle(.titleAndIcon)
      }
      .keyboardShortcut("S")
            
      Button(action: toggleKeyboardLock) {
        Label("\(getLockLabel(isKeyboardLockEnabled)) Keyboard", systemImage: "keyboard")
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
    if (isScreenLockEnabled || isKeyboardLockEnabled) {
      return "lock.circle.fill"
    }
    
    return "lock.circle"
  }
  
  func getLockLabel(_ isLocked: Bool) -> String {
    return isLocked ? "Unlock" : "Lock";
  }
  
  func toggleScreenAndKeyboardLock() {
    isScreenLockEnabled.toggle()
    
    if isScreenLockEnabled {
      isKeyboardLockEnabled = true
      appDelegate.showLockScreenWindow()
      appDelegate.lockKeyboard()
    } else {
      isKeyboardLockEnabled = false
      appDelegate.hideLockScreenWindow()
      appDelegate.unlockKeyboard()
    }
  }
  
  func toggleKeyboardLock() {
    isKeyboardLockEnabled.toggle()
    
    if isKeyboardLockEnabled {
      appDelegate.lockKeyboard()
    } else {
      appDelegate.unlockKeyboard()
    }
  }
  
  func quit() {
    NSApplication.shared.terminate(nil)
  }
}


class AppDelegate: NSObject, NSApplicationDelegate {
  var window: NSWindow?
  var eventTap: CFMachPort?
  var runLoopSource: CFRunLoopSource?
  
  func applicationDidFinishLaunching(_ notification: Notification) {
    // nothin, absolutly nothin
  }
  
  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false
  }
  
  func showLockScreenWindow() {
    if let lockWindow = self.window {
      lockWindow.makeKeyAndOrderFront(self)
      lockWindow.toggleFullScreen(self)
    } else {
      createLockWindow()
    }
  }
  
  func hideLockScreenWindow() {
    if let lockWindow = self.window {
      lockWindow.close()
    }
  }
    
  func createLockWindow() {
    guard let screen = NSScreen.main else { return }
    let screenFrame = screen.frame
    
    let lockWindow = NSWindow(
      contentRect: screenFrame,
      styleMask: [.fullSizeContentView, .titled, .resizable],
      backing: .buffered,
      defer: false,
      screen: NSScreen.main
    )
    
    lockWindow.center()
    lockWindow.title = "Lock for \(screen.localizedName)"
    lockWindow.contentView = NSHostingView(rootView: LockScreenView(screenName: screen.localizedName))
    lockWindow.isReleasedWhenClosed = false
    lockWindow.makeKeyAndOrderFront(self)
    lockWindow.toggleFullScreen(self)
    
    self.window = lockWindow
  }
  
  func lockKeyboard () {
    if let eventTap = self.eventTap {
      CGEvent.tapEnable(tap: eventTap, enable: true)
    } else {
      setupEventTap()
    }
  }
  
  func unlockKeyboard () {
    if let eventTap = self.eventTap {
      CGEvent.tapEnable(tap: eventTap, enable: false)
    }
  }
  
  func setupEventTap() {
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
  
  func destroyEventTap() {
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
}


func blockAllEvents(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, refcon: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
  return nil
}
