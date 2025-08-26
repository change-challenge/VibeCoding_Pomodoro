import SwiftUI
import AppKit

@main
struct PomodoroApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            PreferencesView()
                .environmentObject(AppEnvironment.shared.timer)
                .environmentObject(AppEnvironment.shared.prefs)
        }
    }
}

final class AppEnvironment {
    static let shared = AppEnvironment()
    let timer = TimerService()
    let prefs = PreferencesStore()
    let notifications = NotificationService()
    let menuBar = MenuBarController()
    let floating = FloatingTimerWindowController()
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        let env = AppEnvironment.shared
        env.notifications.requestAuthorization()

        env.menuBar.bind(to: env.timer, prefs: env.prefs)
        env.floating.bind(to: env.timer, prefs: env.prefs)

        #if canImport(Carbon)
        HotkeyService.shared.onStartPause = { [weak env] in env?.timer.toggleStartPause() }
        HotkeyService.shared.onSkip = { [weak env] in env?.timer.skip() }
        HotkeyService.shared.onReset = { [weak env] in env?.timer.reset() }
        HotkeyService.shared.registerDefaults()
        #endif

        SleepObserver.shared.onWake = { [weak t = env.timer] in t?.recalculateRemaining() }
        SleepObserver.shared.onTimeChanged = { [weak t = env.timer] in t?.recalculateRemaining() }

        env.menuBar.show()
        env.floating.show()
    }

    func applicationWillTerminate(_ notification: Notification) {
        #if canImport(Carbon)
        HotkeyService.shared.unregisterAll()
        #endif
    }
}