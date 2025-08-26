import AppKit
import SwiftUI

final class FloatingTimerWindowController {
    private var window: NSPanel?
    private var timer: TimerService?
    private var prefs: PreferencesStore?

    func bind(to timer: TimerService, prefs: PreferencesStore) {
        self.timer = timer
        self.prefs = prefs
    }

    func show() {
        guard window == nil else { 
            window?.makeKeyAndOrderFront(nil)
            return 
        }
        
        let content = TimerView()
            .environmentObject(AppEnvironment.shared.timer)
            .environmentObject(AppEnvironment.shared.prefs)

        let panel = NSPanel(
            contentRect: NSRect(x: 100, y: 600, width: 220, height: 280),
            styleMask: [.nonactivatingPanel, .titled, .fullSizeContentView],
            backing: .buffered, 
            defer: false
        )
        
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.fullScreenAuxiliary, .canJoinAllSpaces]
        panel.isMovableByWindowBackground = true
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.standardWindowButton(.zoomButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.contentView = NSHostingView(rootView: content)
        panel.backgroundColor = .clear
        panel.isOpaque = false

        window = panel
        panel.makeKeyAndOrderFront(nil)
    }
}

struct TimerView: View {
    @EnvironmentObject var timer: TimerService
    @EnvironmentObject var prefs: PreferencesStore

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(lineWidth: 12)
                    .opacity(0.15)
                    .foregroundColor(colorForMode())
                
                Circle()
                    .trim(from: 0, to: timer.progress)
                    .stroke(style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .foregroundColor(colorForMode())
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.1), value: timer.progress)
                
                VStack(spacing: 4) {
                    Text(formatTime(timer.remaining))
                        .font(.system(size: 32, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                    
                    Text(timer.mode.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 160, height: 160)

            HStack(spacing: 12) {
                Button(action: { timer.toggleStartPause() }) {
                    Image(systemName: timer.isRunning ? "pause.fill" : "play.fill")
                        .font(.title2)
                }
                .keyboardShortcut(.init("s"), modifiers: [.option, .command])
                
                Button(action: { timer.skip() }) {
                    Image(systemName: "forward.fill")
                        .font(.title2)
                }
                .keyboardShortcut(.rightArrow, modifiers: [.option, .command])
                
                Button(action: { timer.reset() }) {
                    Image(systemName: "gobackward")
                        .font(.title2)
                }
                .keyboardShortcut(.init("r"), modifiers: [.option, .command])
            }
            .buttonStyle(.borderless)

            Text("오늘 \(timer.cyclesCompletedToday)회 완료")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(8)
        .frame(minWidth: 220, minHeight: 280)
    }

    private func colorForMode() -> Color {
        switch timer.mode {
        case .focus: return .red
        case .shortBreak: return .green
        case .longBreak: return .blue
        case .idle: return .gray
        }
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        if seconds.isNaN || seconds.isInfinite { return "--:--" }
        let s = Int(max(0, seconds))
        let m = s / 60
        let r = s % 60
        return String(format: "%02d:%02d", m, r)
    }
}

struct PreferencesView: View {
    @EnvironmentObject var prefs: PreferencesStore

    var body: some View {
        Form {
            Section("시간 설정 (분)") {
                HStack {
                    Text("집중 시간")
                    Spacer()
                    Stepper(
                        value: Binding(
                            get: { Int(prefs.focusSec/60) }, 
                            set: { prefs.focusSec = TimeInterval($0*60) }
                        ), 
                        in: 1...180
                    ) {
                        Text("\(Int(prefs.focusSec/60))분")
                    }
                }
                
                HStack {
                    Text("짧은 휴식")
                    Spacer()
                    Stepper(
                        value: Binding(
                            get: { Int(prefs.shortBreakSec/60) }, 
                            set: { prefs.shortBreakSec = TimeInterval($0*60) }
                        ), 
                        in: 1...60
                    ) {
                        Text("\(Int(prefs.shortBreakSec/60))분")
                    }
                }
                
                HStack {
                    Text("긴 휴식")
                    Spacer()
                    Stepper(
                        value: Binding(
                            get: { Int(prefs.longBreakSec/60) }, 
                            set: { prefs.longBreakSec = TimeInterval($0*60) }
                        ), 
                        in: 1...120
                    ) {
                        Text("\(Int(prefs.longBreakSec/60))분")
                    }
                }
                
                HStack {
                    Text("긴 휴식까지 사이클")
                    Spacer()
                    Stepper(value: $prefs.cyclesPerLong, in: 1...12) {
                        Text("\(prefs.cyclesPerLong)회")
                    }
                }
            }
            
            Section("자동화") {
                Toggle("다음 단계 자동 시작", isOn: $prefs.autostartNext)
                Toggle("전체화면 시 조용히", isOn: $prefs.quietFullscreen)
            }
        }
        .padding()
        .frame(width: 450, height: 400)
    }
}