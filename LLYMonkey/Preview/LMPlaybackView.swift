//
//  LMPlaybackView.swift
//  LLYMonkey
//
//  Created by lly on 2021/2/19.
//  Copyright © 2021 lly. All rights reserved.
//

import UIKit
import AVFoundation

class LMPlaybackView: UIView {
    
    override class var layerClass: AnyClass {
        get {
            return AVPlayerLayer.self
        }
    }
    
    var player : AVPlayer?
        
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        
        backgroundColor = .black
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func prepare(player : AVPlayer) {
        
        self.player = player
        
        (self.layer as! AVPlayerLayer).videoGravity = .resizeAspectFill
        (self.layer as! AVPlayerLayer).player = player
        
    }

}
