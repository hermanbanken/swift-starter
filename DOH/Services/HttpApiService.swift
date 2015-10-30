//
//  HttpApiService.swift
//  DOH
//
//  Created by H.J. Banken on 30/10/15.
//  Copyright © 2015 nl.tudelft.ch. All rights reserved.
//

import Alamofire
import Promissum
import Promissum_Alamofire

class HttpApiService : ApiService {

  // MARK: ApiService

  func getItems(storeId: String) -> Promise<[Item],ApiError> {
    return requestGet("\(baseUrl)", decoder: ItemList.decodeJson)
      .map { $0.items }
      .mapError(ApiError.init)
  }

  // MARK: Setup

  private let baseUrl: String
  private let networkActivityIndicatorManager: NetworkActivityIndicatorManager
  private let manager: Manager

  init(endpoint: Host, networkActivityIndicatorManager: NetworkActivityIndicatorManager) {
    self.baseUrl = endpoint.apiEndpointURL.absoluteString
    self.networkActivityIndicatorManager = networkActivityIndicatorManager

    // Configure Alamofire
    let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
    configuration.HTTPAdditionalHeaders = Manager.defaultHTTPHeaders

    self.manager = Manager(configuration: configuration)
  }

  // MARK: Request helpers

  private func requestGet<T>(url: URLStringConvertible, parameters: [String: AnyObject]? = nil, decoder: AnyObject -> T?) -> Promise<T, AlamofirePromiseError> {
    return request(.GET, url: url, parameters: parameters, encoding: .URL, decoder: decoder)
  }

  private func requestPostJson<T>(url: URLStringConvertible, parameters: [String: AnyObject]? = nil, decoder: AnyObject -> T?) -> Promise<T, AlamofirePromiseError> {
    return request(.POST, url: url, parameters: parameters, encoding: .JSON, decoder: decoder)
  }

  private func requestPostForm<T>(url: URLStringConvertible, parameters: [String: AnyObject]? = nil, decoder: AnyObject -> T?) -> Promise<T, AlamofirePromiseError> {
    return request(.POST, url: url, parameters: parameters, encoding: .URL, decoder: decoder)
  }

  private func requestPutJson<T>(url: URLStringConvertible, parameters: [String: AnyObject]? = nil, decoder: AnyObject -> T?) -> Promise<T, AlamofirePromiseError> {
    return request(.PUT, url: url, parameters: parameters, encoding: .JSON, decoder: decoder)
  }

  private func requestPutBody<T>(url: URLStringConvertible, body: NSData, decoder: AnyObject -> T?) -> Promise<T, AlamofirePromiseError> {
    func setBody(req: NSMutableURLRequest) -> NSURLRequest {
      req.HTTPBody = body
      req.setValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-Type")
      req.setValue("\(body.length)", forHTTPHeaderField: "Content-Length")
      return req
    }

    return requestBody(.PUT, url: url, requestFactory: setBody, decoder: decoder)
  }

  private func requestDeleteJson<T>(url: URLStringConvertible, parameters: [String: AnyObject]? = nil, decoder: AnyObject -> T?) -> Promise<T, AlamofirePromiseError> {
    return request(.DELETE, url: url, parameters: parameters, encoding: .JSON, decoder: decoder)
  }

  private func request<T>(method: Alamofire.Method, url: URLStringConvertible, parameters: [String: AnyObject]? = nil, encoding: ParameterEncoding, decoder: AnyObject -> T?) -> Promise<T, AlamofirePromiseError> {

    return self.requestBody(method, url: url, requestFactory: { req in encoding.encode(req, parameters: parameters).0 }, decoder: decoder)

  }

  private func requestBody<T>(method: Alamofire.Method, url: URLStringConvertible, requestFactory: NSMutableURLRequest -> NSURLRequest, decoder: AnyObject -> T?) -> Promise<T, AlamofirePromiseError> {
    let request = makeRequest(method, url: url, requestFactory: requestFactory)

    networkActivityIndicatorManager.increment()
    return request
      .responseDecodePromise(decoder)
      .trap(logServerError)
      .finally(networkActivityIndicatorManager.decrement)
  }

  private func request(method: Alamofire.Method, url: URLStringConvertible, parameters: [String: AnyObject]? = nil, encoding: ParameterEncoding) -> Promise<String, AlamofirePromiseError> {
    return self.requestBody(method, url: url, requestFactory: { req in encoding.encode(req, parameters: parameters).0 })
  }

  private func requestBody(method: Alamofire.Method, url: URLStringConvertible, requestFactory: NSMutableURLRequest -> NSURLRequest) -> Promise<String, AlamofirePromiseError> {
    let request = makeRequest(method, url: url, requestFactory: requestFactory)

    networkActivityIndicatorManager.increment()
    return request
      .responseStringPromise()
      .trap(logServerError)
      .finally(networkActivityIndicatorManager.decrement)
  }

  private func makeRequest(method: Alamofire.Method, url: URLStringConvertible, requestFactory: NSMutableURLRequest -> NSURLRequest) -> Alamofire.Request {
    // Generate a requestId for async logging
    let requestId = NSUUID().UUIDString
    let mutableURLRequest = NSMutableURLRequest(URL: NSURL(string: url.URLString)!)

    mutableURLRequest.HTTPMethod = method.rawValue
    mutableURLRequest.setValue(NSUserDefaults.standardUserDefaults().deviceId, forHTTPHeaderField: "Device-Token")

    let request = manager.request(requestFactory(mutableURLRequest))

    let urlDescription = request.request?.URL?.description ?? "nil"
    print("[RID: \(requestId)]: \(method.rawValue) \(urlDescription)")

    // Log responses
    request.response { (_, response, data, error) in
      if let resp = response {
        print("[RID: \(requestId)]: STATUS \(resp.statusCode) \(urlDescription)")
      }
      else if let error = error {
        print("[RID: \(requestId)]: ERROR \(urlDescription) \(error)")
      }
      else {
        print("[RID: \(requestId)]: EMPTY RESPONSE \(urlDescription)")
      }
    }
    
    return request
  }

  // MARK: Error handlers

  private func logServerError(error: AlamofirePromiseError) {

    if case .HttpError(500, let result) = error,
      let resultValue = result?.value {
        print(resultValue)
    }
  }

}

// MARK: Request

extension Request {
  public func responseStringPromise() -> Promise<String, AlamofirePromiseError> {
    let source = PromiseSource<String, AlamofirePromiseError>()

    self.response(responseSerializer: Request.stringResponseSerializer()) {request, response, result in
      let newResult = Request.convertToResultAnyObject(result)

      if let resp = response {
        if resp.statusCode == 404 {
          source.reject(AlamofirePromiseError.HttpNotFound(result: newResult))
          return
        }

        if resp.statusCode < 200 || resp.statusCode > 299 {
          source.reject(AlamofirePromiseError.HttpError(status: resp.statusCode, result: newResult))
          return
        }
      }

      switch result {
      case let .Failure(data, error):
        source.reject(AlamofirePromiseError.UnknownError(error: error, data: data))
      case let .Success(value):
        source.resolve(value)
      }
    }

    return source.promise
  }

  private static func convertToResultAnyObject(result: Alamofire.Result<String>) -> Alamofire.Result<AnyObject> {
    switch result {
    case let .Failure(data, error):
      return Alamofire.Result.Failure(data, error)
    case let .Success(value):
      return Alamofire.Result.Success(value)
    }
  }
}

// MARK: Endpoints

enum Host: String {
  case Production = "127.0.0.1:8080"

  var domain: String {
    return rawValue
  }

  var url: NSURL! {
    return NSURL(scheme: "http", host: rawValue, path: "/")
  }

  var apiEndpointURL: NSURL {
    switch self {
    case .Production: return url.URLByAppendingPathComponent("")
    }
  }
}