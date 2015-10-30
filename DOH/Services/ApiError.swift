//
//  ApiError.swift
//  DOH
//
//  Created by H.J. Banken on 30/10/15.
//  Copyright © 2015 nl.tudelft.ch. All rights reserved.
//

import Foundation
import Alamofire
import Promissum
import Promissum_Alamofire

enum ApiError : ErrorType {
  case NotAuthenticated
  case UnknownJsonData
  case NotImposeable
  case NotificationNotRegistered
  case Unknown
  case NotFound

  case NoInternet(error: NSError)
  case Network(error: NSError)
}

extension ApiError {

  init(alamofirePromiseError: AlamofirePromiseError) {
    switch alamofirePromiseError {
    case .HttpNotFound:
      self = .Unknown

    case .HttpError(401, _):
      self = .NotAuthenticated

    case .HttpError:
      self = .Unknown

    case .JsonDecodeError:
      self = .UnknownJsonData

    case .UnknownError(let error as NSError, _) where error.domain == NSURLErrorDomain && error.code == NSURLErrorNotConnectedToInternet:
      self = .NoInternet(error: error)

    case .UnknownError(let error as NSError, _) where error.domain == NSURLErrorDomain:
      self = .Network(error: error)

    case .UnknownError(let error as NSError, _) where error.domain == NSPOSIXErrorDomain:
      self = .Network(error: error)

    case .UnknownError:
      self = .Unknown
    }
  }
}
