import Foundation
import Combine

final class PreferencesStore: ObservableObject {
    @Published var focusSec: TimeInterval {
        didSet { UserDefaults.standard.set(focusSec, forKey: "focusSec") }
    }
    
    @Published var shortBreakSec: TimeInterval {
        didSet { UserDefaults.standard.set(shortBreakSec, forKey: "shortBreakSec") }
    }
    
    @Published var longBreakSec: TimeInterval {
        didSet { UserDefaults.standard.set(longBreakSec, forKey: "longBreakSec") }
    }
    
    @Published var cyclesPerLong: Int {
        didSet { UserDefaults.standard.set(cyclesPerLong, forKey: "cyclesPerLong") }
    }
    
    @Published var autostartNext: Bool {
        didSet { UserDefaults.standard.set(autostartNext, forKey: "autostartNext") }
    }
    
    @Published var quietFullscreen: Bool {
        didSet { UserDefaults.standard.set(quietFullscreen, forKey: "quietFullscreen") }
    }

    init() {
        self.focusSec = UserDefaults.standard.double(forKey: "focusSec") == 0 ? 25*60 : UserDefaults.standard.double(forKey: "focusSec")
        self.shortBreakSec = UserDefaults.standard.double(forKey: "shortBreakSec") == 0 ? 5*60 : UserDefaults.standard.double(forKey: "shortBreakSec")
        self.longBreakSec = UserDefaults.standard.double(forKey: "longBreakSec") == 0 ? 15*60 : UserDefaults.standard.double(forKey: "longBreakSec")
        self.cyclesPerLong = UserDefaults.standard.integer(forKey: "cyclesPerLong") == 0 ? 4 : UserDefaults.standard.integer(forKey: "cyclesPerLong")
        self.autostartNext = UserDefaults.standard.object(forKey: "autostartNext") as? Bool ?? true
        self.quietFullscreen = UserDefaults.standard.object(forKey: "quietFullscreen") as? Bool ?? true
    }
}

final class SleepObserver {
    static let shared = SleepObserver()
    var onWake: (() -> Void)?
    var onTimeChanged: (() -> Void)?

    private var observers: [Any] = []

    private init() {
        let nc = NSWorkspace.shared.notificationCenter
        
        observers.append(
            nc.addObserver(
                forName: NSWorkspace.screensDidWakeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.onWake?()
            }
        )
        
        observers.append(
            nc.addObserver(
                forName: NSWorkspace.sessionDidBecomeActiveNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.onWake?()
            }
        )
        
        observers.append(
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name.NSSystemClockDidChange,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.onTimeChanged?()
            }
        )
    }
}

import AppKit