//
//  LMAudioSource.swift
//  LLYMonkey
//
//  Created by lly on 2020/7/26.
//  Copyright © 2020 lly. All rights reserved.
//

import UIKit
import AVFoundation

class LMAudioSource: LMAVSource {
    
    let sessionQueue = DispatchQueue(label: "com.llymonkey.avsession.audioqueue")
    let captureSession = AVCaptureSession()
    var device : AVCaptureDevice?
    let audioOutput = AVCaptureAudioDataOutput()
    var delegate : AVAudioSourceProtocol?
    
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
    
    func runing() {
        
        captureSession.startRunning()
        
    }
    
    func stop() {
        
        captureSession.stopRunning()
        
    }
}

extension LMAudioSource : AVCaptureAudioDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let delegate = self.delegate else {
            return
        }
        delegate.audioCaptureOutput(output, didOutput: sampleBuffer, from: connection)
        
    }
    
}
