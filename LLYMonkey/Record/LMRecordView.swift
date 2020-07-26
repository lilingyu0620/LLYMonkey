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
    
    private let videoSource : LMVideoSource = LMVideoSource()
    private var videoWriter : LMVideoWriter!
    
    private let audioSource : LMAudioSource = LMAudioSource()
    private var audioWriter : LMAudioWriter!
    
    var isRecording : Bool = false
    
    var videoIsReadyToWrite : Bool = false
    var audioIsReadyToWrite : Bool = false
    
    /// 分段保存
    var index : Int = 0
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        
        setupUI()
        
        videoSourceRuning()
        
        audioSourceRuning()
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        
        backgroundColor = .red
        
        layer.addSublayer(previewLayer)
        
        addSubview(startBtn)
        
    }
    
    func videoSourceRuning() {
        
        do {
           try videoSource.setupVideoSession()
        }
        catch {
           
        }

        videoSource.setupOrientation()

        videoSource.delegate = self
        
        videoSource.runing()
        
    }
    
    func audioSourceRuning() {
        
        do {
            try audioSource.setupAudioSession()
        }
        catch {
            
        }
        
        audioSource.delegate = self
        
        audioSource.runing()
        
    }
    
    override func layoutSubviews() {
        
        super.layoutSubviews()
        
        previewLayer.frame = self.bounds
        
        startBtn.frame = CGRect(x: (self.bounds.width - UI.startBtnSize) * 0.5, y: self.bounds.height - UI.startBtnSize - UI.startBtnBottom, width: UI.startBtnSize, height: UI.startBtnSize)
        
    }
    
    // MARK - Action
    
    @objc func startBtnClicked() {
        
        self.isRecording = !self.isRecording
        
        if self.isRecording {
            start()
        }
        else {
            stop()
        }
    }
    
    private func start() {
        
        videoWriter = LMVideoWriter(with: "\(index)")
        audioWriter = LMAudioWriter(with: "\(index)")
        
        index += 1
    }
    
    private func stop() {
        
//        videoSource.stop()
//        audioSource.stop()
        
        videoWriter.stop()
        audioWriter.stop()
    }
    
}

extension LMRecordView : AVVideoSourceProtocol {
    
    func videoCaptureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if self.previewLayer.status == .failed {
           self.previewLayer.flush()
        }
        else {
           self.previewLayer.enqueue(sampleBuffer)
        }
        if isRecording {
            if !self.videoIsReadyToWrite {
                guard let format = CMSampleBufferGetFormatDescription(sampleBuffer) else {
                    return
                }
                videoWriter.addTrack(sourceFormatDescription: format, settings: nil)
                videoWriter.prepareForWrite()
                self.videoIsReadyToWrite = true
            }
            videoWriter.append(sampleBuffer)
        }
        else {
            if self.videoIsReadyToWrite {
                self.videoIsReadyToWrite = false
            }
        }
    }
}

extension LMRecordView : AVAudioSourceProtocol {
    
    func audioCaptureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if isRecording {
            if !self.audioIsReadyToWrite {
                guard let format = CMSampleBufferGetFormatDescription(sampleBuffer) else {
                    return
                }
                audioWriter.addTrack(sourceFormatDescription: format, settings: nil)
                audioWriter.prepareForWrite()
                self.audioIsReadyToWrite = true
            }
            audioWriter.append(sampleBuffer)
        }
        else {
            if self.audioIsReadyToWrite {
                self.audioIsReadyToWrite = false
            }
        }
    }
    
}
