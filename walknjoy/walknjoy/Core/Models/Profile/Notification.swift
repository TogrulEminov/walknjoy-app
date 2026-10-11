//
//  NotificationRequest.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 25.09.26.
//

import Foundation

struct Notification:Codable {
    let bookingUpdates: Bool
    let messages: Bool
    let marketing: Bool
}
