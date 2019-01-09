//
//  BuggyEngine.swift
//  BuggyEngine
//
//  Created by Harvey He on 2019/1/8.
//

import UIKit
import PromiseKit
import WebKit
import WKWebViewJavascriptBridge
public class BuggyEngine: NSObject {
    
    var manager = BuggyManager.getInstance()
    public var delegate:BuggyEngineDelegate?
    fileprivate var bridge:WKWebViewJavascriptBridge?
    fileprivate var wkWebView =  WKWebView()
    public override init() {
        super.init()
    }
    
    public func initBuggy(){
        _ = registerWebViewBridge().then{_ in
            return self.loadFirmataResource()
            }.then{_ in
                return after(seconds:2)
            }.then{_ in
                return self.connectBuggy()
            }
    }

    func connectBuggy()->Promise<String>{
         bridge?.call(handlerName: "deviceConnect", data:nil, callback: nil)
         return Promise{seal in seal.fulfill("OK")}
    }
    
    func loadFirmataResource()->Promise<String>{
        let resourcePath = Bundle.main.bundlePath
        let pathURL = URL.init(fileURLWithPath: resourcePath)
        let html = Bundle.main.path(forResource: "firmata", ofType: "html")
        do {
            let content = try String(contentsOf: URL.init(fileURLWithPath: html!), encoding: String.Encoding.utf8)
            wkWebView.loadHTMLString(content, baseURL: pathURL)
        }
        catch _{}
        return after(seconds:1).then{return Promise{seal in seal.fulfill("OK")}}
    }
    
    func registerWebViewBridge()->Promise<String>{
        bridge = WKWebViewJavascriptBridge(webView: wkWebView)
        bridge?.register(handlerName: "bleConnect") { (paramters, callback) in
            _ = self.initCommunicator().done{_ in
                callback?("success")
            }
        }
        
        bridge?.register(handlerName: "sendMsgPromise") { (paramters, callback) in
            let data = paramters!["data"] as! NSDictionary
            self.sendData(data: data.object(forKey:"data")! as! Array<UInt8>)
            callback?("success")
        }
        
        bridge?.register(handlerName: "connectTimeOut") { (paramters, callback) in
            let path = Bundle.main.path(forResource:"firmataCorePlusIBB", ofType:"bin")
            let data = NSData(contentsOfFile:path!)
            _ = self.resetBuggyAndUpload(data:data!)
        }
        
        bridge?.register(handlerName: "disconnect") { (paramters, callback) in
            print("scratch response","连接断开")
        }
        
        bridge?.register(handlerName: "connectReady") { (paramters, callback) in
            print("scratch response","连接成功")
        }
        return Promise{seal in seal.fulfill("OK")}
    }
    
    public func initCommunicator()->Promise<String>{
        manager.delegate = self
        manager.communucationType = .control
        return manager.connectionIO == nil ? initConnect() : firmataReady()
    }
    
    func setCommunicatorType(type:CommunucationType){
        manager.communucationType = type
    }
    
    public func initConnect()->Promise<String>{
        return self.manager.initCentralManager().then{_ in
            return self.manager.startScan()
            }.then{_ in
                return self.manager.connectDevice()
        }
    }
    
    public func resetBuggyAndUpload(data:NSData)->Promise<String>{
        manager.communucationType = .upload
        return self.uploadHex(data:data as Data)
    }
    
    func resetBuggy()->Promise<[UInt8]>{
        return manager.setUploadBaudrate() .then { _ in
            return self.manager.resetDevice()
            }.then{ _ in
                return self.manager.getCoreType()
            }.then{ _ in
                return self.manager.keepSync()
            }.then{ _ in
                return self.manager.setDevice()
        }
    }
    
    func uploadHex(data:Data)->Promise<String>{
        return self.resetBuggy().then { _ in
            return self.manager.enterProgramming()
            }.then { _ in
                return self.manager.uploadData(hexData: data)
            }.then{ _ in
                return self.manager.exitProgramming()
            }.then{ _ in
                return self.manager.setCommunicatorBaudrate()
        }
    }
    
    public func sendData(data:[UInt8]){
        self.manager.managerWriteValue(self.manager.connectionIO!, msg: data)
    }
    
    func firmataReady()->Promise<String>{
        return after(seconds:0.020).then{return Promise{seal in seal.fulfill("OK")}}
    }
}


extension BuggyEngine:BuggyManagerDelegate{
    
    public func firmataReceviceData(inputData: [UInt8]) {
        bridge?.call(handlerName: "handleNotification", data:["data":inputData], callback: nil)
    }
    
}
