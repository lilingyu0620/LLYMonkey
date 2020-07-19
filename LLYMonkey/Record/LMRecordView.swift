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
    let audioOutput = AVCaptureAudioDataOutput()
    
    var isRecording : Bool = false
    
    var videoAssetWriter : AVAssetWriter?
    var audioAssetWriter : AVAssetWriter?
    var videoHasStartSession : Bool = false
    var audioHasStartSession : Bool = false
    var videoIsReadyToWrite : Bool = false
    var audioIsReadyToWrite : Bool = false
    
    var videoInput : AVAssetWriterInput?
    var videoInputSetting : [String : Any]? = nil
    var videoTrackTransform = CGAffineTransform.identity
    var videoTrackSourceFormatDescription : CMFormatDescription? = nil
    var videoEncodingIsFinished : Bool = false
    let writeQueue = DispatchQueue(label: "com.llymonkey.avwrite.queue")
    
    var audioInput : AVAssetWriterInput?
    var audioInputSetting : [String : Any]? = nil
    var audioTrackTransform = CGAffineTransform.identity
    var audioTrackSourceFormatDescription : CMFormatDescription? = nil
    var audioEncodingIsFinished : Bool = false
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        
        setupUI()
        
        do {
            try setupVideoSession()
        }
        catch {
            
        }
        
        do {
            try setupAudioSession()
        }
        catch {
            
        }
        
        setupOrientation()
    
        captureSession.startRunning()
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func setupVideoSession() throws {
        
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
    
    func setupAudioSession() throws {
        
        captureSession.beginConfiguration()
        
        guard let device = AVCaptureDevice.default(for: AVMediaType.audio) else {
            throw ConfigError.unSupported
        }
        let input = try AVCaptureDeviceInput(device: device)
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }
        else {
            throw ConfigError.unSupported
        }
        
        audioOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        captureSession.usesApplicationAudioSession = true
        captureSession.automaticallyConfiguresApplicationAudioSession = true
        
        if captureSession.canAddOutput(audioOutput) {
            captureSession.addOutput(audioOutput)
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
    
    func addAudioTrack(sourceFormatDescription: CMFormatDescription, settings:[String: Any]?) {
        self.audioTrackSourceFormatDescription = sourceFormatDescription
        self.audioInputSetting = settings
    }
    
    func getVideoInputSetting() -> [String :Any] {
        
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
    
    func getAudioInputSetting() -> [String: Any] {
        let audioSetting = [
            AVFormatIDKey:kAudioFormatMPEG4AAC,
            AVSampleRateKey:44100,
            AVNumberOfChannelsKey:1
        ] as [String:Any]
        return audioSetting
    }
    
    func setupVideoInput() {
        
        self.videoInputSetting = getVideoInputSetting()
        
        guard let assetWriter = self.videoAssetWriter else {
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
    
    func setupAudioInput() {
        
        self.audioInputSetting = getAudioInputSetting()
        
        guard let assetWriter = self.audioAssetWriter else {
            return
        }
        
        guard assetWriter.canApply(outputSettings: self.audioInputSetting, forMediaType: .audio) else {
            return
        }
        
        let audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: self.audioInputSetting)
        guard assetWriter.canAdd(audioInput) else {
            return
        }
        assetWriter.add(audioInput)
        
        self.audioInput = audioInput
    }
    
    func prepareForWrite() {
        
        writeQueue.async { [weak self] in
                   
            autoreleasepool(invoking: {
               
                do {
                                        
                    if self?.videoTrackSourceFormatDescription != nil {
                        guard let url = self?.pathForAsset(with: "videotest.mov") else {
                            return
                        }
                        let writer = try AVAssetWriter(outputURL: url, fileType: .mov)
                        writer.movieFragmentInterval = CMTimeMakeWithSeconds(1.0, preferredTimescale: 1000)
                        self?.videoAssetWriter = writer
                        self?.setupVideoInput()
                    }
                    
                    if self?.audioTrackSourceFormatDescription != nil {
                        guard let url = self?.pathForAsset(with: "videotest.m4a") else {
                           return
                        }
                        let writer = try AVAssetWriter(outputURL: url, fileType: .mov)
                        writer.movieFragmentInterval = CMTimeMakeWithSeconds(1.0, preferredTimescale: 1000)
                        self?.audioAssetWriter = writer
                        self?.setupAudioInput()
                    }
                    
                    if let success = self?.videoAssetWriter?.startWriting() {
                        if success {
                            print("video startWriting success")
                        }
                        else {
                            print("video startWriting fail")
                        }
                    }
                    
                    if let success = self?.audioAssetWriter?.startWriting() {
                        if success {
                            print("audio startWriting success")
                        }
                        else {
                            print("audio startWriting fail")
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
        
        guard let videoWriter = self.videoAssetWriter, let audioWriter = self.audioAssetWriter, let videoInput = self.videoInput, let audioInput = self.audioInput else {
            return
        }
        
        guard let format = CMSampleBufferGetFormatDescription(sampleBuffer) else {
            return
        }
        
        let mediaType = CMFormatDescriptionGetMediaType(format)
        
        writeQueue.async { [weak self] in
            
            guard let strongSelf = self else {
                return
            }
            
            autoreleasepool(invoking: {
                
                if !strongSelf.videoHasStartSession, mediaType == kCMMediaType_Video {
                    videoWriter.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
                    strongSelf.videoHasStartSession = true
                }
                
                if !strongSelf.audioHasStartSession, mediaType == kCMMediaType_Audio {
                    audioWriter.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
                    strongSelf.audioHasStartSession = true
                }
                
                let input = (mediaType == kCMMediaType_Video) ? videoInput : audioInput
                
                guard input.isReadyForMoreMediaData else {
                    return
                }
                
                let success = input.append(sampleBuffer)
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
        
        guard let videoWriter = self.videoAssetWriter, let audioWriter = self.audioAssetWriter else {
            return
        }
        
        guard let videoInput = self.videoInput, let audioInput = self.audioInput else {
            return
        }
        
        writeQueue.async { [weak self] in
            
            guard let strongSelf = self else {
                return
            }
            
            strongSelf.videoEncodingIsFinished = true
            
            videoInput.markAsFinished()
            audioInput.markAsFinished()
            
            videoWriter.finishWriting(completionHandler: {
                
                print("video stop success")

            })
            
            audioWriter.finishWriting {
                
                print("audio stop success")
                
            }
            
        }
        
    }
    
    
}

extension LMRecordView : AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
        
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let format = CMSampleBufferGetFormatDescription(sampleBuffer) else {
            return
        }
        let mediaType = CMFormatDescriptionGetMediaType(format)
        if mediaType == kCMMediaType_Video {
            if self.previewLayer.status == .failed {
                self.previewLayer.flush()
            }
            else {
                self.previewLayer.enqueue(sampleBuffer)
            }
        }
        
        if self.isRecording {
            
            if !self.videoIsReadyToWrite, mediaType == kCMMediaType_Video {
                
                self.videoTrackSourceFormatDescription = format
                
                self.prepareForWrite()
                
                self.videoIsReadyToWrite = true
            }
            
            if !self.audioIsReadyToWrite, mediaType == kCMMediaType_Audio {
                
                self.audioTrackSourceFormatDescription = format

                self.prepareForWrite()
                
                self.audioIsReadyToWrite = true
            }
            
            self.append(sampleBuffer)
            
        }
        else {
            
            
            
        }
        
    }
    
}
