import Foundation
import Combine

final class TimerService: ObservableObject {
    enum Mode: String, CaseIterable {
        case idle, focus, shortBreak, longBreak
        
        var displayName: String {
            switch self {
            case .idle: return "준비"
            case .focus: return "집중"
            case .shortBreak: return "짧은 휴식"
            case .longBreak: return "긴 휴식"
            }
        }
    }

    @Published private(set) var mode: Mode = .idle
    @Published private(set) var isRunning: Bool = false
    @Published private(set) var remaining: TimeInterval = 0
    @Published private(set) var cyclesCompletedToday: Int = 0
    @Published private(set) var progress: Double = 0

    private var startAt: Date?
    private var endAt: Date?
    private var displayTimer: DispatchSourceTimer?
    private var focusCount: Int = 0

    var prefs: PreferencesStore? { didSet { recalculateRemaining() } }

    func configure(with prefs: PreferencesStore) { 
        self.prefs = prefs 
    }

    func start(_ newMode: Mode? = nil) {
        if let m = newMode { mode = m }
        if mode == .idle { mode = .focus }

        let duration = durationFor(mode)
        startAt = Date()
        endAt = startAt!.addingTimeInterval(duration)
        isRunning = true
        scheduleDisplayTimer()
    }

    func toggleStartPause() {
        if isRunning {
            pause()
        } else if remaining > 0 {
            resume()
        } else {
            start()
        }
    }

    func pause() {
        guard isRunning else { return }
        isRunning = false
        if let endAt { remaining = max(0, endAt.timeIntervalSinceNow) }
        displayTimer?.cancel()
        displayTimer = nil
    }

    func resume() {
        guard !isRunning, remaining > 0 else { return }
        startAt = Date()
        endAt = startAt!.addingTimeInterval(remaining)
        isRunning = true
        scheduleDisplayTimer()
    }

    func reset() {
        isRunning = false
        mode = .idle
        startAt = nil
        endAt = nil
        remaining = 0
        progress = 0
        displayTimer?.cancel()
        displayTimer = nil
    }

    func skip() {
        completeCurrent(didSkip: true)
    }

    func recalculateRemaining() {
        guard let endAt else { return }
        remaining = max(0, endAt.timeIntervalSinceNow)
        updateProgress()
        if remaining <= 0 { handleFinished() }
    }

    private func scheduleDisplayTimer() {
        displayTimer?.cancel()
        let t = DispatchSource.makeTimerSource(queue: .main)
        t.schedule(deadline: .now(), repeating: .milliseconds(100))
        t.setEventHandler { [weak self] in self?.tick() }
        displayTimer = t
        t.resume()
    }

    private func tick() {
        guard let endAt else { return }
        remaining = max(0, endAt.timeIntervalSinceNow)
        updateProgress()
        if remaining <= 0 { handleFinished() }
    }

    private func updateProgress() {
        let dur = durationFor(mode)
        if dur > 0 { 
            progress = max(0, min(1, 1 - remaining / dur)) 
        } else { 
            progress = 0 
        }
    }

    private func handleFinished() {
        isRunning = false
        displayTimer?.cancel()
        displayTimer = nil
        completeCurrent(didSkip: false)
    }

    private func completeCurrent(didSkip: Bool) {
        if !didSkip { 
            AppEnvironment.shared.notifications.fire(modeCompleted: mode) 
        }

        if mode == .focus && !didSkip {
            focusCount += 1
            cyclesCompletedToday += 1
        }

        let next: Mode
        switch mode {
        case .focus:
            if focusCount > 0, let prefs, focusCount % max(1, prefs.cyclesPerLong) == 0 {
                next = .longBreak
            } else {
                next = .shortBreak
            }
        case .shortBreak, .longBreak:
            next = .focus
        case .idle:
            next = .focus
        }

        mode = next
        if let prefs, prefs.autostartNext { 
            start(next) 
        } else { 
            recalcIdleRemaining(next) 
        }
    }

    private func recalcIdleRemaining(_ upcoming: Mode) {
        startAt = nil
        endAt = nil
        remaining = durationFor(upcoming)
        progress = 0
    }

    private func durationFor(_ mode: Mode) -> TimeInterval {
        guard let p = prefs else { return 0 }
        switch mode {
        case .focus: return p.focusSec
        case .shortBreak: return p.shortBreakSec
        case .longBreak: return p.longBreakSec
        case .idle: return 0
        }
    }
}