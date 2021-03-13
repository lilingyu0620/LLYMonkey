//
//  LMContextManager.swift
//  LLYMonkey
//
//  Created by lly on 2021/2/19.
//  Copyright © 2021 lly. All rights reserved.
//

import UIKit

class LMContextManager: NSObject {
    
    static let shareInstance = LMContextManager()
    
    let eaglContext : CVEAGLContext
    let ciContext : CIContext
    
    override init() {
        
        self.eaglContext = EAGLContext.init(api: EAGLRenderingAPI.openGLES2)!
        self.ciContext = CIContext.init(eaglContext: self.eaglContext, options: nil)  //CIContext.init(cgContext: self.eaglContext as! CGContext, options: nil)
        
    }

}
