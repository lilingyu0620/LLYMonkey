//
//  LMVideoWriter.swift
//  LLYMonkey
//
//  Created by lly on 2020/7/26.
//  Copyright © 2020 lly. All rights reserved.
//

import UIKit
import AVFoundation
import CoreImage

class LMVideoWriter: LMAssertWriter {
    
    let writeQueue = DispatchQueue(label: "com.llymonkey.videowrite.queue")
    let fileName : String
    var assetWriteInputPixelBufferAdaptor : AVAssetWriterInputPixelBufferAdaptor?
    let ciContext : CIContext
    var ciFilter : CIFilter
    var colorSapce : CGColorSpace
    
    init(with fileName:String) {
        
        self.fileName = fileName
        
        self.ciContext = LMContextManager.shareInstance.ciContext
        
        self.ciFilter = LMPhotoFilters.shared.defaultFilter()!
        
        self.colorSapce = CGColorSpaceCreateDeviceRGB()
        
        super.init()
        
        NotificationCenter.default.addObserver(self, selector: #selector(filterChange), name: NSNotification.Name(rawValue: LMPhotoFilters.FilterChangeNotification), object: nil)
        
    }
    
    @objc func filterChange(notification : Notification) {
        self.ciFilter = notification.object as! CIFilter
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
        
        if let input = self.avInput {
            
            self.assetWriteInputPixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: pixelBufferAdaptorAttributes())
            
        }
       
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
                        writer.movieFragmentInterval = CMTimeMakeWithSeconds(1.0, preferredTimescale: 600)
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
                
                var outputRenderBuffer : CVPixelBuffer?
                
                // 加滤镜
                if let pixelBufferPool = self?.assetWriteInputPixelBufferAdaptor?.pixelBufferPool {
                    
                    CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferPool, &outputRenderBuffer)
                    
                    if let imgBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
                        
                        let sourceImage = CIImage.init(cvPixelBuffer: imgBuffer, options: nil)
                        
                        self?.ciFilter.setValue(sourceImage, forKey: kCIInputImageKey)
                        
                        var filterImage = self?.ciFilter.outputImage
                        
                        if let _ = filterImage {
                        }
                        else {
                            filterImage = sourceImage
                        }
                        
                        if let filterImg = filterImage,let buffer = outputRenderBuffer {
                            
                            self?.ciContext.render(filterImg, to: buffer, bounds: filterImg.extent, colorSpace: self?.colorSapce)
                            
                            let success = self?.assetWriteInputPixelBufferAdaptor?.append(buffer, withPresentationTime: CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
                            
                            if let s = success, s == true {
                                print("filter video append success")
                            }
                            else {
                                print("filter video append fail")
                            }

                            
                        }
                    }
                    
                }
                else {
                 
                    let success = avInput.append(sampleBuffer)
                    if success {
                        print("video append success")
                    }
                    else {
                        print("video append fail")
                    }
                    
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
    
    private func pixelBufferAdaptorAttributes() -> [String:Any] {
        
        guard let formatDescription = self.avTrackSourceFormatDescription else {
            return [:]
        }
        
        let dimensions = CMVideoFormatDescriptionGetDimensions(formatDescription)
        let attributes = [kCVPixelBufferPixelFormatTypeKey as String : kCVPixelFormatType_32BGRA,
                          kCVPixelBufferWidthKey as String : dimensions.width,
                          kCVPixelBufferHeightKey as String : dimensions.height,
                          kCVPixelFormatOpenGLESCompatibility as String : kCFBooleanTrue!] as [String : Any]
        return attributes
        
    }

}
