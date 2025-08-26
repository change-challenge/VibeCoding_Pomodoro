#if canImport(Carbon)
import Carbon
import Cocoa

final class HotkeyService {
    static let shared = HotkeyService()

    var onStartPause: (() -> Void)?
    var onSkip: (() -> Void)?
    var onReset: (() -> Void)?

    private var eventHandler: EventHandlerRef?
    private var hk1: EventHotKeyRef?
    private var hk2: EventHotKeyRef?
    private var hk3: EventHotKeyRef?

    private init() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetEventDispatcherTarget(), { (_, event, _) -> OSStatus in
            var hkID = EventHotKeyID()
            let res = GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hkID)
            guard res == noErr else { return res }
            
            switch hkID.id {
            case 1: HotkeyService.shared.onStartPause?()
            case 2: HotkeyService.shared.onSkip?()
            case 3: HotkeyService.shared.onReset?()
            default: break
            }
            return noErr
        }, 1, &eventType, nil, &eventHandler)
    }

    func registerDefaults() {
        unregisterAll()
        let mods = UInt32(cmdKey | optionKey)
        
        var id1 = EventHotKeyID(signature: FourCharCode("POMO"), id: 1)
        RegisterEventHotKey(UInt32(kVK_ANSI_S), mods, id1, GetEventDispatcherTarget(), 0, &hk1)
        
        var id2 = EventHotKeyID(signature: FourCharCode("POMO"), id: 2)
        RegisterEventHotKey(UInt32(kVK_RightArrow), mods, id2, GetEventDispatcherTarget(), 0, &hk2)
        
        var id3 = EventHotKeyID(signature: FourCharCode("POMO"), id: 3)
        RegisterEventHotKey(UInt32(kVK_ANSI_R), mods, id3, GetEventDispatcherTarget(), 0, &hk3)
    }

    func unregisterAll() {
        if let hk1 { UnregisterEventHotKey(hk1) }
        if let hk2 { UnregisterEventHotKey(hk2) }
        if let hk3 { UnregisterEventHotKey(hk3) }
        hk1 = nil; hk2 = nil; hk3 = nil
    }
}

extension FourCharCode: ExpressibleByStringLiteral {
    public init(stringLiteral value: StringLiteralType) {
        var result: FourCharCode = 0
        for char in value.utf16 {
            result = (result << 8) + FourCharCode(char)
        }
        self = result
    }
}

#endif