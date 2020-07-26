//
//  LMAudioWriter.swift
//  LLYMonkey
//
//  Created by lly on 2020/7/26.
//  Copyright © 2020 lly. All rights reserved.
//

import UIKit
import AVFoundation

class LMAudioWriter: LMAssertWriter {
    
    let writeQueue = DispatchQueue(label: "com.llymonkey.audiowrite.queue")
    let fileName : String
       
    init(with fileName:String) {
       
       self.fileName = fileName
       
       super.init()
       
    }
    
    func setupAudioInput() {
        
        self.avInputSetting = getAudioInputSetting()
        
        guard let assetWriter = self.avAssetWriter else {
            return
        }
        
        guard assetWriter.canApply(outputSettings: self.avInputSetting, forMediaType: .audio) else {
            return
        }
        
        let audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: self.avInputSetting)
        guard assetWriter.canAdd(audioInput) else {
            return
        }
        assetWriter.add(audioInput)
        
        self.avInput = audioInput
    }
    
    func prepareForWrite() {
        
        guard self.status == .idle else {
            debugPrint("audio writer already prepared, cannot prepare again")
            return
        }
        
        self.status = .preparingToWrite
        
        writeQueue.async { [weak self] in
                   
            guard let strongSelf = self else {
                return
            }
            
            autoreleasepool(invoking: {
               
                do {
                                        
                    if self?.avTrackSourceFormatDescription != nil {
                        guard let url = self?.pathForAsset(with: "\(strongSelf.fileName).m4a") else {
                            return
                        }
                        let writer = try AVAssetWriter(outputURL: url, fileType: .mov)
                        writer.movieFragmentInterval = CMTimeMakeWithSeconds(1.0, preferredTimescale: 1000)
                        self?.avAssetWriter = writer
                        self?.setupAudioInput()
                    }
                    
                    
                    if let success = self?.avAssetWriter?.startWriting() {
                        if success {
                            self?.status = .writing
                            print("audio startWriting success")
                        }
                        else {
                            self?.status = .failed
                            print("audio startWriting fail")
                        }
                    }
                    
                }
                catch {
                    self?.status = .failed
                    print("audio startWriting fail")
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
                    print("audio append success")
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
                
                print("audio stop success")

            })
        }
        
    }

    
    private func getAudioInputSetting() -> [String: Any] {
       let audioSetting = [
           AVFormatIDKey:kAudioFormatMPEG4AAC,
           AVSampleRateKey:44100,
           AVNumberOfChannelsKey:1
       ] as [String:Any]
       return audioSetting
    }
    
}
