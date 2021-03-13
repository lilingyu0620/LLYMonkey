//
//  LMCompositionExporter.swift
//  LLYMonkey
//
//  Created by lly on 2021/2/19.
//  Copyright © 2021 lly. All rights reserved.
//

import UIKit
import AVFoundation
import AssetsLibrary

class LMCompositionExporter: NSObject {
    
    let composition : LMBaseComposition
    var exportSession : AVAssetExportSession?
    
    init(composition : LMBaseComposition) {
        
        self.composition = composition
        
    }
    
    func beginExport() {
        
        self.exportSession = self.composition.makeExportSession()
        self.exportSession?.outputURL = pathForAsset(with: "tmp.mp4")
        self.exportSession?.outputFileType = AVFileType.mp4
        
        self.exportSession?.exportAsynchronously(completionHandler: { [weak self] in
                        
            DispatchQueue.main.async { [weak self] in
                let status = self?.exportSession?.status
                if status == AVAssetExportSession.Status.completed {
                    print("export success")
                    self?.writeExportedVideoToAssetsLibrary()
                }
                else {
                    print("export error")
                }
            }
            
        })
        
    }
    
    
    // MARK: - Private Method
    
    func writeExportedVideoToAssetsLibrary() {
        
        let exportUrl = pathForAsset(with: "tmp.mp4")
        let library = ALAssetsLibrary()
        if library.videoAtPathIs(compatibleWithSavedPhotosAlbum: exportUrl) {
            library.writeVideoAtPath(toSavedPhotosAlbum: exportUrl) { (assetUrl, error) in
                if let err = error {
                    print("writeExportedVideoToAssetsLibrary error")
                }
                else {
                    print("writeExportedVideoToAssetsLibrary success")
                    try?FileManager.default.removeItem(at: exportUrl)
                }
            }
        }
        
    }
    
    func pathForAsset(with name: String) -> URL {
        let dirUrl = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("videoclips")
        if !FileManager.default.fileExists(atPath: dirUrl.path) {
           try? FileManager.default.createDirectory(at: dirUrl, withIntermediateDirectories: true, attributes: nil)
        }
        let fileUrl = dirUrl.appendingPathComponent(name)
        return fileUrl
    }


}
