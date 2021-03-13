//
//  LMBaseComposition.swift
//  LLYMonkey
//
//  Created by lly on 2021/2/18.
//  Copyright © 2021 lly. All rights reserved.
//

import UIKit
import AVFoundation

class LMBaseComposition: NSObject {
    
    var composition : AVComposition
    
    init(composition : AVComposition) {
        self.composition = composition
    }
    
    func makePlayable() -> AVPlayerItem {
        return AVPlayerItem.init(asset: self.composition.copy() as! AVAsset)
    }

    func makeExportSession() -> AVAssetExportSession? {
        return AVAssetExportSession.init(asset: self.composition.copy() as! AVAsset, presetName: AVAssetExportPresetHighestQuality)
    }
    
}
