//
//  NotificationService.swift
//  NotificationService
//
//  Created by Tyler Hammer on 2023/06/08.
//

import UserNotifications

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        guard let bestAttemptContent = bestAttemptContent else { return }
        let userInfo = bestAttemptContent.userInfo
        
        guard let payload: NSDictionary = userInfo["sendbird"] as? NSDictionary,
              let channel: NSDictionary = payload["channel"] as? NSDictionary,
              let channelURL: String = channel["channel_url"] as? String else { return }

        // Modify the notification content here...
        bestAttemptContent.title = "This is channelURL: \(channelURL)"
        bestAttemptContent.body = ""
        
            
        contentHandler(bestAttemptContent)
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

}
 
