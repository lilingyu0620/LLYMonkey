//
//  LMAirSandbox.swift
//  LLYMonkey
//
//  Created by lly on 2020/7/18.
//  Copyright © 2020 lly. All rights reserved.
//

import UIKit

class LMAirSandbox: NSObject {
    
    struct UI {
        static let windowPadding : CGFloat = 20
    }
    
    static let shared = LMAirSandbox()
    
    var popupWindow : UIWindow?
    
    let sandboxBrowser = ASViewController()
    
    func show() {
        
        let windowScene = UIApplication.shared
                        .connectedScenes
                        .filter { $0.activationState == .foregroundActive }
                        .first
        if let windowScene = windowScene as? UIWindowScene {
            var keyFrame = UIScreen.main.bounds;
            keyFrame.origin.y += 64;
            keyFrame.size.height -= 64;
            popupWindow = UIWindow(windowScene: windowScene)
            popupWindow?.frame = keyFrame.insetBy(dx: UI.windowPadding, dy: UI.windowPadding);
            popupWindow?.backgroundColor = .white
            popupWindow?.layer.borderColor = UIColor.black.cgColor;
            popupWindow?.layer.borderWidth = 2.0;
            popupWindow?.windowLevel = UIWindow.Level.statusBar + 1
            popupWindow?.rootViewController = sandboxBrowser
            popupWindow?.makeKeyAndVisible()
        }
        
    }

}
