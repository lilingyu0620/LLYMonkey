//
//  LMVideoWriter.swift
//  LLYMonkey
//
//  Created by lly on 2020/7/26.
//  Copyright © 2020 lly. All rights reserved.
//

import UIKit
import AVFoundation

class LMVideoWriter: LMAssertWriter {
    
    let writeQueue = DispatchQueue(label: "com.llymonkey.videowrite.queue")
    let fileName : String
    
    init(with fileName:String) {
        
        self.fileName = fileName
        
        super.init()
        
    }
    
    func setupVideoInput() {
           
       self.avInputSetting = getVideoInputSetting()
       
       guard let assetWriter = self.avAssetWriter else {
           return
       }
       
       guard assetWriter.canApply(outputSettings: self.avInputSetting, forMediaType: .video) else {
           return
       }
       
       let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: self.avInputSetting)
       videoInput.expectsMediaDataInRealTime = true
       
       guard assetWriter.canAdd(videoInput) else {
           return
       }
       assetWriter.add(videoInput)
       
       self.avInput = videoInput
       
    }
    
    func prepareForWrite() {
        
        guard self.status == .idle else {
            debugPrint("video writer already prepared, cannot prepare again")
            return
        }
        
        self.status = .preparingToWrite
        
        writeQueue.async { [weak self] in
            
            guard let strongSelf = self else {
                return
            }
                   
            autoreleasepool(invoking: {
               
                do {
                                        
                    if strongSelf.avTrackSourceFormatDescription != nil {
                        let url = strongSelf.pathForAsset(with: "\(strongSelf.fileName).mov")
                        let writer = try AVAssetWriter(outputURL: url, fileType: .mov)
                        writer.movieFragmentInterval = CMTimeMakeWithSeconds(1.0, preferredTimescale: 1000)
                        strongSelf.avAssetWriter = writer
                        strongSelf.setupVideoInput()
                    }
                    
                    
                    if let success = strongSelf.avAssetWriter?.startWriting() {
                        if success {
                            strongSelf.status = .writing
                            print("video startWriting success")
                        }
                        else {
                            strongSelf.status = .failed
                            print("video startWriting fail")
                        }
                    }
                    
                }
                catch {
                    strongSelf.status = .failed
                    print("video startWriting fail")
                }
               
           })

        }
        
    }
    
    func append(_ sampleBuffer: CMSampleBuffer, completed:(()->Void)? = nil) {
        
        guard CMSampleBufferIsValid(sampleBuffer) else {
            return
        }
        
        guard let avWriter = self.avAssetWriter, let avInput = self.avInput else {
            return
        }
        
//        guard let format = CMSampleBufferGetFormatDescription(sampleBuffer) else {
//            return
//        }
//
//        let mediaType = CMFormatDescriptionGetMediaType(format)
        
        writeQueue.async { [weak self] in
            
            guard let strongSelf = self else {
                return
            }
            
            autoreleasepool(invoking: {
                
                if !strongSelf.avHasStartSession {
                    avWriter.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
                    strongSelf.avHasStartSession = true
                }
                
                guard avInput.isReadyForMoreMediaData else {
                    return
                }
                
                let success = avInput.append(sampleBuffer)
                if success {
                    print("video append success")
                }
                else {
                    print("audio append fail")
                }
            })
            
        }
        
    }
    
    func stop() {
        
        guard let avWriter = self.avAssetWriter else {
            return
        }
        
        guard let avInput = self.avInput else {
            return
        }
        
        writeQueue.async { [weak self] in
            
            guard let strongSelf = self else {
                return
            }
            
            strongSelf.status = .finishingWriting
            
            strongSelf.avEncodingIsFinished = true
            
            avInput.markAsFinished()
            
            avWriter.finishWriting(completionHandler: {
                
                print("video stop success")

            })
        }
        
    }

    
    private func getVideoInputSetting() -> [String :Any] {
        
        guard let formatDescription = self.avTrackSourceFormatDescription else {
            return [:]
        }
        
        let dimensions = CMVideoFormatDescriptionGetDimensions(formatDescription)
        
        let numPixels : Float = Float(dimensions.width * dimensions.height)
        var bitsPerPixel : Float = 0
        var bitsPerSecond : Float = 0
        
        if numPixels <= 640 * 480 {
            bitsPerPixel = 4.05
        }
        else {
            bitsPerPixel = 10.1
        }
        
        bitsPerSecond = bitsPerPixel * numPixels
        
        let compressionProperties = [
            AVVideoAverageBitRateKey : bitsPerSecond,
            AVVideoExpectedSourceFrameRateKey : 30,
            AVVideoMaxKeyFrameIntervalKey : 30
        ] as [String: Any]
        
        let videoSetting = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: dimensions.width,
            AVVideoHeightKey: dimensions.height,
            AVVideoCompressionPropertiesKey: compressionProperties
        ] as [String: Any]
        
        return videoSetting
    }

}
