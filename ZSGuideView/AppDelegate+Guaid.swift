//
//  AppDelegate+Guaid.swift
//  GuideView
//
//  Created by 赵帅 on 2017/6/8.
//  Copyright © 2017年 sun5kong. All rights reserved.
//

import UIKit


extension AppDelegate {
    
    
    private struct AssociatedKeys {
        static var guideWindowKey = "guideWindowKey"
    }
    
    private var guaidWindow: UIWindow? {
        
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.guideWindowKey) as? UIWindow
        }
    
        set {
            if newValue != nil {
                objc_setAssociatedObject(self, &AssociatedKeys.guideWindowKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }
    
    public override class func initialize(){

        let lastVersion = UserDefaults.standard.float(forKey: "lastVersionKey")
        let currentVersion = Float((Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "0")!
        if currentVersion > lastVersion {
            DispatchQueue.once(token: "交换appDelegate方法") {
                
                
                let originalMethod = class_getInstanceMethod(self, #selector(application(_:didFinishLaunchingWithOptions:)))
                let customMethod = class_getInstanceMethod(self, #selector(guide_application(_:didFinishLaunchingWithOptions:)))
                method_exchangeImplementations(originalMethod, customMethod)
                
                
            }
        
        }
        
        
    }
    
    
    func guide_application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        
        guaidWindow = UIWindow()
        guaidWindow!.frame = UIScreen.main.bounds
        guaidWindow!.backgroundColor = UIColor.white
        guaidWindow!.windowLevel = UIWindowLevelStatusBar + 1
        self.guaidWindow!.makeKeyAndVisible()
        
        let vc = ZSGuaidViewController()
        vc.hide = {[weak self] in
            print("1111")
            let currentVersion = Float((Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "0")!
            UserDefaults.standard.set(currentVersion, forKey: "lastVersionKey")
            UserDefaults.standard.synchronize()
            
            self?.guaidWindow?.resignKey()
            self?.guaidWindow?.isHidden = true
            self?.guaidWindow = nil
        }
        
        guaidWindow?.rootViewController = vc
        return guide_application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
}


extension DispatchQueue {
    
    private static var _onceTracker = [String]()
    
    public class func once(token: String, block:() -> Void) {
        objc_sync_enter(self)
        defer {
            objc_sync_enter(self)
        }
        
        if _onceTracker.contains(token) {
            return
        }
        
        _onceTracker.append(token)
        block()
    }
    
}
