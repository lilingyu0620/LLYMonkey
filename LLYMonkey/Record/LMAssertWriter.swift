//
//  LMAssertWriter.swift
//  LLYMonkey
//
//  Created by lly on 2020/7/26.
//  Copyright © 2020 lly. All rights reserved.
//

import UIKit
import AVFoundation

class LMAssertWriter: NSObject {
    
    enum AssetWriterStatus {
        case idle
        case preparingToWrite
        case writing
        case finishingWriting
        case finished // terminal state
        case failed // terminal state
        case canceled
    }
    
    var avAssetWriter : AVAssetWriter?
    var avInput : AVAssetWriterInput?
    var avInputSetting : [String : Any]? = nil
    var avTrackTransform = CGAffineTransform.identity
    var avTrackSourceFormatDescription : CMFormatDescription? = nil
    var avEncodingIsFinished : Bool = false
    var avHasStartSession : Bool = false
    var status: AssetWriterStatus = .idle
    
    func pathForAsset(with name: String) -> URL {
        let dirUrl = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("videoclips")
        if !FileManager.default.fileExists(atPath: dirUrl.path) {
           try? FileManager.default.createDirectory(at: dirUrl, withIntermediateDirectories: true, attributes: nil)
        }
        let fileUrl = dirUrl.appendingPathComponent(name)
        if FileManager.default.fileExists(atPath: fileUrl.path) {
           try? FileManager.default.removeItem(at: fileUrl)
        }
        return fileUrl
    }
    
    func addTrack(sourceFormatDescription: CMFormatDescription, settings:[String: Any]?) {
        self.avTrackSourceFormatDescription = sourceFormatDescription
        self.avInputSetting = settings
    }
    
}
