//
//  LMCompositionBuilder.swift
//  LLYMonkey
//
//  Created by lly on 2021/2/18.
//  Copyright © 2021 lly. All rights reserved.
//

import UIKit
import AVFoundation
import CoreMedia

class LMCompositionBuilder: NSObject {
    
    var videos : [LMMediaItem] = []
    var voices : [LMMediaItem] = []
    
    let composition = AVMutableComposition()
    
    func buildComposition() -> LMBaseComposition {
        
        addCompositionTrack(mediaType: AVMediaType.video, mediaItems: videos)
        
        addCompositionTrack(mediaType: AVMediaType.audio, mediaItems: voices)
        
        return LMBaseComposition(composition: self.composition)
        
    }
    
    
    // MARK: - Private
    
    private func addCompositionTrack(mediaType : AVMediaType, mediaItems : [LMMediaItem]) {
        
        if mediaItems.count > 0 {
            
            let trackID = kCMPersistentTrackID_Invalid
            
            let compositionTrack = self.composition.addMutableTrack(withMediaType: mediaType, preferredTrackID: trackID)
            
            var cursorTime = CMTime.zero
            
            for item in mediaItems {
                let assetTrack = item.asset.tracks(withMediaType: mediaType).first
                if let cTrack = compositionTrack, let aTrack = assetTrack {
                    do {
                        try cTrack.insertTimeRange(item.timeRange, of: aTrack, at: cursorTime)
                    }
                    catch {
                        
                    }
                    cursorTime = CMTimeAdd(cursorTime, item.timeRange.duration)
                }
            }
            
        }
        
    }

}
