import Foundation
import UserNotifications
import AppKit

final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    
    func requestAuthorization() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("알림 권한 요청 실패: \(error)")
            } else {
                print("알림 권한 \(granted ? "허용됨" : "거부됨")")
            }
        }
    }

    func fire(modeCompleted mode: TimerService.Mode) {
        let content = UNMutableNotificationContent()
        
        switch mode {
        case .focus:
            content.title = "집중 시간 완료!"
            content.body = "수고했습니다. 잠시 휴식을 취하세요."
        case .shortBreak:
            content.title = "휴식 완료!"
            content.body = "다시 집중할 시간입니다."
        case .longBreak:
            content.title = "긴 휴식 완료!"
            content.body = "새로운 집중 세션을 시작하세요."
        case .idle:
            return
        }
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("알림 전송 실패: \(error)")
            }
        }
        
        NSApp.requestUserAttention(.informationalRequest)
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .list])
    }
}