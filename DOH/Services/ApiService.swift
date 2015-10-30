//
//  File.swift
//  DOH
//
//  Created by H.J. Banken on 30/10/15.
//  Copyright © 2015 nl.tudelft.ch. All rights reserved.
//

import Foundation
import Promissum
import Promissum_Alamofire

protocol ApiService {

  // Dummy
  func getItems(storeId: String) -> Promise<[Item],ApiError>

}