//
//  LMVideoSource.swift
//  LLYMonkey
//
//  Created by lly on 2020/7/26.
//  Copyright © 2020 lly. All rights reserved.
//

import UIKit
import AVFoundation

class LMVideoSource: LMAVSource {
    
    let sessionQueue = DispatchQueue(label: "com.llymonkey.avsession.videoqueue")
    let captureSession = AVCaptureSession()
    var device : AVCaptureDevice?
    let videoOutput = AVCaptureVideoDataOutput()
    var delegate : AVVideoSourceProtocol?
    
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
    
    func setupOrientation() {
        
        if let connection = self.videoOutput.connection(with: .video) {
            connection.isVideoMirrored = true
            connection.videoOrientation = .portrait
        }
        
    }
    
    func runing() {
        
        captureSession.startRunning()
        
    }
    
    func stop() {
        
        captureSession.stopRunning()
        
    }
    
}

extension LMVideoSource : AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let delegate = self.delegate else {
            return
        }
        delegate.videoCaptureOutput(output, didOutput: sampleBuffer, from: connection)
        
    }
    
}
