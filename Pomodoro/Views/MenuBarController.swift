import AppKit
import SwiftUI

final class MenuBarController {
    private var statusItem: NSStatusItem!
    private var timer: TimerService?
    private var prefs: PreferencesStore?
    private var updateTimer: Timer?

    func bind(to timer: TimerService, prefs: PreferencesStore) {
        self.timer = timer
        self.prefs = prefs
        timer.configure(with: prefs)
        startMenuTitleUpdater()
    }

    func show() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "⚪️ --:--"
        statusItem.menu = buildMenu()
    }

    private func startMenuTitleUpdater() {
        updateTimer?.invalidate()
        updateTimer = Foundation.Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.refreshTitle()
        }
    }

    private func refreshTitle() {
        guard let t = timer else { return }
        let timeStr = Self.formatTime(t.remaining)
        let symbol: String
        
        switch t.mode {
        case .focus: symbol = "🔴"
        case .shortBreak: symbol = "🟢"
        case .longBreak: symbol = "🔵"
        case .idle: symbol = "⚪️"
        }
        
        statusItem.button?.title = "\(symbol) \(timeStr)"
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()
        
        menu.addItem(withTitle: "시작/일시정지 (⌥⌘S)", action: #selector(toggleStartPause), keyEquivalent: "")
        menu.addItem(withTitle: "건너뛰기 (⌥⌘→)", action: #selector(skip), keyEquivalent: "")
        menu.addItem(withTitle: "리셋 (⌥⌘R)", action: #selector(reset), keyEquivalent: "")
        menu.addItem(.separator())
        
        let todayItem = NSMenuItem(title: "오늘: --", action: nil, keyEquivalent: "")
        todayItem.isEnabled = false
        menu.addItem(todayItem)
        
        menu.addItem(.separator())
        menu.addItem(withTitle: "설정…", action: #selector(openPrefs), keyEquivalent: ",")
        menu.addItem(withTitle: "종료", action: #selector(quit), keyEquivalent: "q")
        
        menu.items.forEach { $0.target = self }
        return menu
    }

    @objc private func toggleStartPause() { 
        timer?.toggleStartPause() 
    }
    
    @objc private func skip() { 
        timer?.skip() 
    }
    
    @objc private func reset() { 
        timer?.reset() 
    }
    
    @objc private func openPrefs() { 
        NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil) 
    }
    
    @objc private func quit() { 
        NSApp.terminate(nil) 
    }

    private static func formatTime(_ seconds: TimeInterval) -> String {
        if seconds.isNaN || seconds.isInfinite { return "--:--" }
        let s = Int(max(0, seconds))
        let m = s / 60
        let r = s % 60
        return String(format: "%02d:%02d", m, r)
    }
}