//
//  LMPreviewView.swift
//  LLYMonkey
//
//  Created by lly on 2021/2/19.
//  Copyright © 2021 lly. All rights reserved.
//

import UIKit
import GLKit

class LMPreviewView: GLKView {

    var filter : CIFilter?
    var coreImageContext : CIContext?
    var drawableBounds : CGRect?
    
    override init(frame: CGRect, context: EAGLContext) {
        
        super.init(frame: frame, context: context)
        
        self.bindDrawable()
        
        self.drawableBounds = self.bounds
        self.drawableBounds?.size.width = CGFloat(self.drawableWidth)
        self.drawableBounds?.size.height = CGFloat(self.drawableHeight)
        
        NotificationCenter.default.addObserver(self, selector: #selector(filterChange), name: NSNotification.Name(rawValue: LMPhotoFilters.FilterChangeNotification), object: nil)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func filterChange(notification : Notification) {
        self.filter = notification.object as? CIFilter
    }
    
    func setImage(sourceImage : CIImage) {
        
        self.bindDrawable()
        
        self.filter?.setValue(sourceImage, forKey: kCIInputImageKey)
        let filterImage = self.filter?.outputImage
        
        if let filterImg = filterImage, let inRect = self.drawableBounds {
            
            let cropRect = THCenterCropImageRect(sourceRect: sourceImage.extent, previewRect: self.drawableBounds!)
            
            self.coreImageContext?.draw(filterImg, in: inRect, from: cropRect)
                
        }
        
        self.display()
        
        self.filter?.setValue(nil, forKey: kCIInputImageKey)
        
    }
    
    func THCenterCropImageRect(sourceRect : CGRect, previewRect : CGRect) -> CGRect {
        
        let sourceAspectRatio = sourceRect.size.width / sourceRect.size.height
        let previewAspectRatio = previewRect.size.width / previewRect.size.height
        
        var drawRect = sourceRect
        
        if sourceAspectRatio > previewAspectRatio {
            let scaledHeight = drawRect.size.height * previewAspectRatio
            drawRect.origin.x += (drawRect.size.width - scaledHeight) / 2
            drawRect.size.width = scaledHeight
        }
        else {
            drawRect.origin.y += (drawRect.size.height - drawRect.size.width / previewAspectRatio) / 2
            drawRect.size.height = drawRect.size.width / previewAspectRatio
            
        }
        
        return drawRect
        
    }
    
}
