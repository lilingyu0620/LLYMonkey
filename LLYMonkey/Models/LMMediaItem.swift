//
//  LMMediaItem.swift
//  LLYMonkey
//
//  Created by lly on 2021/2/18.
//  Copyright © 2021 lly. All rights reserved.
//

import UIKit
import AVFoundation

typealias LMPreparationCompletionBlock = (_ complete : Bool) -> Void

class LMMediaItem: LMTimelineItem {
    
    struct AVAssetKeys {
        static let TracksKey : String = "tracks"
        static let DurationKey : String = "duration"
        static let CommonMetadataKey : String = "commonMetadata"
    }
    
    var asset : AVAsset
    var mediaType : AVMediaType
    var url : URL
    var prepare : Bool = false
    
    init(url : URL,mediaType : AVMediaType) {
        
        self.url = url
        self.mediaType = mediaType
        self.asset = AVURLAsset.init(url: url,options: [AVURLAssetPreferPreciseDurationAndTimingKey:true])
        
        super.init(timeRange: CMTimeRange.zero, startTimeInTimeline: CMTime.zero)
        
    }
    
    func prepare(with completionBlock : @escaping LMPreparationCompletionBlock) {
        
        self.asset.loadValuesAsynchronously(forKeys: [AVAssetKeys.TracksKey,AVAssetKeys.DurationKey,AVAssetKeys.CommonMetadataKey], completionHandler: {
            
            let tracksStatus = self.asset.statusOfValue(forKey: AVAssetKeys.TracksKey, error: nil)
            let durationStatus = self.asset.statusOfValue(forKey: AVAssetKeys.DurationKey, error: nil)
            
            self.prepare = (tracksStatus == AVKeyValueStatus.init(rawValue: 2)) && (durationStatus == AVKeyValueStatus.init(rawValue: 2))
            
            if self.prepare {
                
                self.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: self.asset.duration)
                
                completionBlock(self.prepare)
                
            }
            else {
                
                completionBlock(false)
                
            }
            
        })
                
    }
    
    func makePlayable() -> AVPlayerItem {
        return AVPlayerItem(asset: self.asset)
    }

}
