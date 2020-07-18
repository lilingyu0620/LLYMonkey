//
//  LMRecordView.swift
//  LLYMonkey
//
//  Created by lly on 2020/7/18.
//  Copyright © 2020 lly. All rights reserved.
//

import UIKit
import GLKit
import AVFoundation

class LMRecordView: UIView {
    
    enum ConfigError: Error {
        case unSupported
        case isAdjusting
        case systemError(Error)
    }
    
    struct UI {
        static let startBtnSize : CGFloat = 100
        static let startBtnBottom : CGFloat = 44
    }
    
    lazy var startBtn : UIButton = {
        let btn = UIButton(frame: .zero)
        btn.backgroundColor = .white
        btn.addTarget(self, action: #selector(startBtnClicked), for: .touchUpInside)
        btn.layer.cornerRadius = UI.startBtnSize / 2
        return btn
    }()
    
    let previewLayer = AVSampleBufferDisplayLayer()
    let sessionQueue = DispatchQueue(label: "com.llymonkey.avsession.queue")
    let captureSession = AVCaptureSession()
    var device : AVCaptureDevice?
    let videoOutput = AVCaptureVideoDataOutput()
    
    var isRecording : Bool = false
    
    var assetWriter : AVAssetWriter?
    var hasStartSession : Bool = false
    var isReadyToWrite : Bool = false
    
    var videoInput : AVAssetWriterInput?
    var videoInputSetting : [String : Any]? = nil
    var videoTrackTransform = CGAffineTransform.identity
    var videoTrackSourceFormatDescription : CMFormatDescription? = nil
    var videoEncodingIsFinished : Bool = false
    let writeQueue = DispatchQueue(label: "com.llymonkey.avsession.queue")
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        
        setupUI()
        
        do {
            try setupSession()
        }
        catch {
            
        }
        
        setupOrientation()
    
        captureSession.startRunning()
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func setupSession() throws {
        
        captureSession.beginConfiguration()
        
        if let device = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: .video, position: AVCaptureDevice.Position.front) {
            
            self.device = device
            
            let input = try AVCaptureDeviceInput(device: device)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
            else {
                throw ConfigError.unSupported
            }
        }
        
        if captureSession.canSetSessionPreset(AVCaptureSession.Preset.hd1280x720) {
            captureSession.sessionPreset = .hd1280x720
        }
        else if captureSession.canSetSessionPreset(AVCaptureSession.Preset.high) {
            captureSession.sessionPreset = .high
        }
        else if captureSession.canSetSessionPreset(.medium) {
            captureSession.sessionPreset = .medium
        }
        
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]
        videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
        else {
            throw ConfigError.unSupported
        }
        
        captureSession.commitConfiguration()
        
    }
    
    func setupOrientation() {
        
        if let connection = self.videoOutput.connection(with: .video) {
            connection.isVideoMirrored = true
            connection.videoOrientation = .portrait
        }
        
    }
    
    func setupUI() {
        
        backgroundColor = .red
        
        layer.addSublayer(previewLayer)
        
        addSubview(startBtn)
        
    }
    
    override func layoutSubviews() {
        
        super.layoutSubviews()
        
        previewLayer.frame = self.bounds
        
        startBtn.frame = CGRect(x: (self.bounds.width - UI.startBtnSize) * 0.5, y: self.bounds.height - UI.startBtnSize - UI.startBtnBottom, width: UI.startBtnSize, height: UI.startBtnSize)
        
    }
    
    // MARK - Action
    
    @objc func startBtnClicked() {
        
        if self.isRecording {
            
            stopWrite()
            
            self.isRecording = false
            
        }
        else {
            
            self.isRecording = true
            
        }
        
    }
    
}


// Record

extension LMRecordView {
    
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
    
    func addVideoTrack(sourceFormatDescription: CMFormatDescription, settings:[String: Any]?) {
        self.videoTrackSourceFormatDescription = sourceFormatDescription
        self.videoInputSetting = settings
    }
    
    func inputSetting() -> [String :Any] {
        
        guard let formatDescription = self.videoTrackSourceFormatDescription else {
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
    
    func setupVideoInput() {
        
        self.videoInputSetting = inputSetting()
        
        guard let assetWriter = self.assetWriter else {
            return
        }
        
        guard assetWriter.canApply(outputSettings: self.videoInputSetting, forMediaType: .video) else {
            return
        }
        
        let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: self.videoInputSetting)
        videoInput.expectsMediaDataInRealTime = true
        
        guard assetWriter.canAdd(videoInput) else {
            return
        }
        assetWriter.add(videoInput)
        
        self.videoInput = videoInput
        
    }
    
    func prepareForWrite() {
        
        writeQueue.async { [weak self] in
                   
            autoreleasepool(invoking: {
               
                do {
                    guard let url = self?.pathForAsset(with: "videotest.mov") else {
                        return
                    }
                    let writer = try AVAssetWriter(outputURL: url, fileType: .mov)
                    writer.movieFragmentInterval = CMTimeMakeWithSeconds(1.0, preferredTimescale: 1000)
                    
                    self?.assetWriter = writer
                    
                    if self?.videoTrackSourceFormatDescription != nil {
                        self?.setupVideoInput()
                    }
                    
                    if let success = self?.assetWriter?.startWriting() {
                        if success {
                            print("startWriting success")
                        }
                        else {
                            print("startWriting fail")
                        }
                    }
                }
                catch {
                    
                }
               
           })

        }
        
    }
    
    func append(_ sampleBuffer: CMSampleBuffer, completed:(()->Void)? = nil) {
        
        guard CMSampleBufferIsValid(sampleBuffer) else {
            return
        }
        
        guard let writer = self.assetWriter, let videoInput = self.videoInput else {
            return
        }
        
        guard let format = CMSampleBufferGetFormatDescription(sampleBuffer) else {
            return
        }
        
        writeQueue.async { [weak self] in
            
            guard let strongSelf = self else {
                return
            }
            
            autoreleasepool(invoking: {
                
                if !strongSelf.hasStartSession {
                    writer.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
                    strongSelf.hasStartSession = true
                }
                
                guard videoInput.isReadyForMoreMediaData else {
                    return
                }
                
                let success = videoInput.append(sampleBuffer)
                if success {
                    print("append success")
                }
                else {
                    print("append fail")
                }
            })
            
        }
        
    }
    
    func stopWrite() {
        
        guard let writer = self.assetWriter else {
            return
        }
        
        guard let videoInput = self.videoInput else {
            return
        }
        
        writeQueue.async { [weak self] in
            
            guard let strongSelf = self else {
                return
            }
            
            strongSelf.videoEncodingIsFinished = true
            
            videoInput.markAsFinished()
            
            writer.finishWriting(completionHandler: {
                
                print("stop success")

            })
            
        }
        
    }
    
    
}

extension LMRecordView : AVCaptureVideoDataOutputSampleBufferDelegate {
        
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if self.previewLayer.status == .failed {
            self.previewLayer.flush()
        }
        else {
            self.previewLayer.enqueue(sampleBuffer)
        }
        
        if self.isRecording {
            
            if !self.isReadyToWrite {
                
                guard let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) else {
                    return
                }
                
                self.videoTrackSourceFormatDescription = formatDescription
                
                self.prepareForWrite()
                
                self.isReadyToWrite = true
                
            }
            
            self.append(sampleBuffer)
            
        }
        else {
            
            
            
        }
        
    }
    
}
