//
//  LMPhotoFilters.swift
//  LLYMonkey
//
//  Created by lly on 2021/2/19.
//  Copyright © 2021 lly. All rights reserved.
//

import UIKit

class LMPhotoFilters: NSObject {
    
    static let shared = LMPhotoFilters()
    
    static let FilterChangeNotification : String = "FilterChangeNotification"
    
    func defaultFilter() -> CIFilter? {
        return CIFilter.init(name: self.filterNames().first!)
    }
    
    func filterNames() -> [String] {
        return ["CIPhotoEffectChrome",
        "CIPhotoEffectFade",
        "CIPhotoEffectInstant",
        "CIPhotoEffectMono",
        "CIPhotoEffectNoir",
        "CIPhotoEffectProcess",
        "CIPhotoEffectTonal",
        "CIPhotoEffectTransfer"]
    }
    
    func fliterDisplayNames() -> [String] {
        
        var result : [String] = []
        
        for fullName in filterNames() {
            
            let suffixIndex = fullName.index(fullName.startIndex, offsetBy: 13)
            let name = String(fullName.suffix(from: suffixIndex))
            
            result.append(name)
            
        }
        
        return result
    }
    
    func filterWithName(filterName : String) -> CIFilter? {
        for name in filterNames() {
            if name.contains(filterName) {
                return CIFilter.init(name: name)
            }
        }
        return nil
    }

}
