//
//  LMAVSource.swift
//  LLYMonkey
//
//  Created by lly on 2020/7/26.
//  Copyright © 2020 lly. All rights reserved.
//

import UIKit
import AVFoundation

protocol AVVideoSourceProtocol {
    func videoCaptureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection);
}

protocol AVAudioSourceProtocol {
    func audioCaptureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection);
}

class LMAVSource: NSObject {
    
    enum ConfigError: Error {
       case unSupported
       case isAdjusting
       case systemError(Error)
    }
}
