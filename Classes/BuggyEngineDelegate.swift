//
//  BuggyEngineDelegate.swift
//  QooBot
//
//  Created by Harvey He on 2018/12/18.
//  Copyright © 2018 Harvey He. All rights reserved.
//
import Foundation
import CoreBluetooth

@objc public protocol BuggyEngineDelegate: class {
   
    @objc optional func firmataReceviceData(inputData:[UInt8])
    
    @objc optional func buggyEngineState(state:BuggyState)
   
    @objc optional func hexUploadProgess(progess:Int)
    
    @objc optional func managerState(state:CBCentralManagerState)
    
    @objc optional func powerWarning()
}
