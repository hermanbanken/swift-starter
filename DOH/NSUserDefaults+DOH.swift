//
//  NSUserDefaults+DOH.swift
//  DOH
//
//  Created by H.J. Banken on 30/10/15.
//  Copyright © 2015 nl.tudelft.ch. All rights reserved.
//

import Foundation

private struct NSUserDefaultKeys {
  static let LastUsedLoginEmailKey = "LastUsedLoginEmailKey"
  static let DeviceIdKey = "DeviceIdKey"
  static let PushTokenKey = "PushTokenKey"
}

extension NSUserDefaults {

  func resetUserData() {
    lastUsedLoginEmail = nil
  }

  var lastUsedLoginEmail: String? {
    get {
      return objectForKey(NSUserDefaultKeys.LastUsedLoginEmailKey) as! String?
    }
    set {
      setObject(newValue, forKey: NSUserDefaultKeys.LastUsedLoginEmailKey)
    }
  }

  var deviceId: String {
    get {

      if let deviceId = objectForKey(NSUserDefaultKeys.DeviceIdKey) as? String {
        return deviceId
      }

      let deviceId = NSUUID().UUIDString
      setObject(deviceId, forKey: NSUserDefaultKeys.DeviceIdKey)
      return deviceId
    }
  }

}