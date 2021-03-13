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

typealias recordFinishBlock = (_ isFinish : Bool,_ segments : Int) -> Void

class LMRecordView: UIView {
        
    struct UI {
        static let startBtnSize : CGFloat = 88
        static let startBtnBottom : CGFloat = 44
        
        static let okBtnSize : CGSize = CGSize(width: 60, height: 40)
        static let okBtnRightMargin : CGFloat = 24
        
        static let filterViewHeight : CGFloat = 64
    }
    
    var finishBlock : recordFinishBlock?
    
    lazy var startBtn : UIButton = {
        let btn = UIButton(frame: .zero)
        btn.backgroundColor = .white
        btn.addTarget(self, action: #selector(startBtnClicked), for: .touchUpInside)
        btn.layer.cornerRadius = UI.startBtnSize / 2
        return btn
    }()
    
    lazy var okBtn : UIButton = {
        let btn = UIButton(frame: .zero)
        btn.backgroundColor = .white
        btn.addTarget(self, action: #selector(okBtnClicked), for: .touchUpInside)
        btn.setTitle("完成", for: .normal)
        btn.setTitleColor(UIColor.red, for: .normal)
        return btn
    }()

    
    lazy var progressTimer : Timer = {
        let timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(progressTimerFire), userInfo: nil, repeats: true)
        return timer
    }()
    
    lazy var progressBar : CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor = UIColor.red.cgColor
        layer.lineWidth = 5
        layer.strokeStart = 0
        layer.strokeEnd = 0
        return layer
    }()
    
    lazy var segmentBar : CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor = UIColor.green.cgColor
        layer.lineWidth = 5
        layer.strokeStart = 0
        layer.strokeEnd = 1
        // 线长，间距
//        layer.lineDashPattern = [NSNumber(value: 5),NSNumber(value: 20)]
        return layer
    }()
    
    
    lazy var filterSelectedView : LMFilterSelectorView = {
        let view = LMFilterSelectorView(frame: CGRect(x: 0, y: LMRecordView.isIphoneX() ? 24 : 0, width: UIScreen.main.bounds.width, height: UI.filterViewHeight))
        return view
    }()
    
    var segmentBarPath : CGMutablePath = CGMutablePath()
    
    let previewLayer = AVSampleBufferDisplayLayer()
    
    var previewView : LMPreviewView?
    
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
        
        self.previewView = LMPreviewView(frame: frame, context: LMContextManager.shareInstance.eaglContext)
        self.previewView?.filter = LMPhotoFilters.shared.defaultFilter()
        self.previewView?.coreImageContext = LMContextManager.shareInstance.ciContext
        
        setupUI()
        
        videoSourceRuning()
        
        audioSourceRuning()
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        
        backgroundColor = .clear
        
//        layer.addSublayer(previewLayer)
        if let preview = self.previewView {
            addSubview(preview)
        }
        
        addSubview(filterSelectedView)
        
        addSubview(startBtn)
        
        layer.addSublayer(progressBar)
        
        layer.addSublayer(segmentBar)
        
        addSubview(okBtn)
        
    }
    
    override func layoutSubviews() {
        
        super.layoutSubviews()
        
//        previewLayer.frame = self.bounds
        previewView?.frame = self.bounds
        
        startBtn.frame = startBtnRect()
        
        let path = UIBezierPath()
        path.addArc(withCenter: CGPoint(x: startBtnRect().midX, y: startBtnRect().midY), radius: UI.startBtnSize / 2, startAngle: -CGFloat(Double.pi) / 2, endAngle: CGFloat(Double.pi)*3/2, clockwise: true)
        progressBar.path = path.cgPath

        okBtn.frame = okBtnRect()
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
    
    @objc func progressTimerFire() {
        
        if progressBar.strokeEnd >= 1 {
            
            stop()
            
            if let block = self.finishBlock {
                block(true,index)
            }
            
        }
        
        progressBar.strokeEnd += (1 / 15 * 0.1)
        
    }
    
    @objc func okBtnClicked() {
        
        if let block = self.finishBlock {
            block(true,index)
        }
        
    }
    
    // MARK - Private
    
    private func startTimer() {
        
        if progressTimer.isValid {
            progressTimer.invalidate()
        }
        
        progressTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(progressTimerFire), userInfo: nil, repeats: true)
        progressTimer.fire()
        
    }
    
    private func stopTimer() {
        
        progressTimer.invalidate()
        
    }
    
    private func start() {
        
        videoWriter = LMVideoWriter(with: "\(index)")
        audioWriter = LMAudioWriter(with: "\(index)")
        
        index += 1
        
        startTimer()
        
    }
    
    private func stop() {
                
        videoWriter.stop()
        audioWriter.stop()
        
        stopTimer()
        
        addSegment()
        
    }
    
    private func startBtnRect() -> CGRect {
        return CGRect(x: (self.bounds.width - UI.startBtnSize) * 0.5, y: self.bounds.height - UI.startBtnSize - UI.startBtnBottom, width: UI.startBtnSize, height: UI.startBtnSize)
    }
    
    private func okBtnRect() -> CGRect {
        return CGRect(x: (self.bounds.width - UI.okBtnSize.width - UI.okBtnRightMargin), y: startBtnRect().minY + (UI.startBtnSize - UI.okBtnSize.height) / 2, width: UI.okBtnSize.width, height: UI.okBtnSize.height)
    }
    
    private func addSegment() {
        
        let path = UIBezierPath()
        let startAngle = -CGFloat(Double.pi) / 2 + progressBar.strokeEnd * CGFloat(Double.pi)*2
        let endAngle = startAngle + CGFloat(Double.pi) * 2 * 10 / 360
        path.addArc(withCenter: CGPoint(x: startBtnRect().midX, y: startBtnRect().midY), radius: UI.startBtnSize / 2, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        segmentBarPath.addPath(path.cgPath)
        
        segmentBar.path = segmentBarPath
        
    }
    
    class func isIphoneX() -> Bool {
        return UIScreen.main.bounds.height >= 812
    }
    
}

extension LMRecordView : AVVideoSourceProtocol {
    
    func videoCaptureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
//        if self.previewLayer.status == .failed {
//           self.previewLayer.flush()
//        }
//        else {
//           self.previewLayer.enqueue(sampleBuffer)
//        }
        
        if let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            
            let sourceImage = CIImage.init(cvImageBuffer: imageBuffer)
            
            self.previewView?.setImage(sourceImage: sourceImage)
            
        }
        
        if isRecording {
            if !self.videoIsReadyToWrite {
                guard let format = CMSampleBufferGetFormatDescription(sampleBuffer) else {
                    return
                }
                guard let vWrite = videoWriter else {
                    return
                }
                vWrite.addTrack(sourceFormatDescription: format)
                vWrite.prepareForWrite()
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
                guard let aWrite = audioWriter else {
                    return
                }
                aWrite.addTrack(sourceFormatDescription: format)
                aWrite.prepareForWrite()
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
