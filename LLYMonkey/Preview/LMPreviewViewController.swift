//
//  LMPreviewViewController.swift
//  LLYMonkey
//
//  Created by lly on 2021/2/18.
//  Copyright © 2021 lly. All rights reserved.
//

import UIKit
import AVFoundation

class LMPreviewViewController: UIViewController {
    
    struct UI {
        static let backBtnSize : CGSize = CGSize(width: 60, height: 40)
        static let backBtnLeftMargin : CGFloat = 24
        static let backBtnTopMargin : CGFloat = 64
        
        static let exportBtnSize : CGSize = CGSize(width: 60, height: 40)
        static let exportBtnRightMargin : CGFloat = 24
        static let exportBtnTopMargin : CGFloat = 64
    }
    
    struct Keys {
        static let statusKeyPath : String = "status"
    }
    
    lazy var backBtn : UIButton = {
        let btn = UIButton(frame: .zero)
        btn.backgroundColor = .white
        btn.addTarget(self, action: #selector(backBtnClicked), for: .touchUpInside)
        btn.setTitle("返回", for: .normal)
        btn.setTitleColor(UIColor.red, for: .normal)
        return btn
    }()
    
    lazy var exportBtn : UIButton = {
        let btn = UIButton(frame: .zero)
        btn.backgroundColor = .white
        btn.addTarget(self, action: #selector(exportBtnClicked), for: .touchUpInside)
        btn.setTitle("导出", for: .normal)
        btn.setTitleColor(UIColor.red, for: .normal)
        return btn
    }()

    
    var segments : Int = 0
    
    let compositionBuilder = LMCompositionBuilder()
    var baseComposition : LMBaseComposition?
    var exporter : LMCompositionExporter?
    
    var playerItem : AVPlayerItem?
    var player : AVPlayer?
    lazy var playbackView : LMPlaybackView = {
        return LMPlaybackView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
    }()
    
    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        setupUI()
        
        loadItems()
        
        // 加个延时 等items的assetload回调成功后才能拿到timerange
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.preparePlay()
        }
        
    }
    
    func setupUI() {
        
        self.view.backgroundColor = UIColor.black

        self.view.addSubview(playbackView)
        
        self.view.addSubview(backBtn)
        
        self.view.addSubview(exportBtn)
        
    }
    
    func loadItems() {
        
        loadVideoItems()
        
        loadVoiceItems()
        
    }
    
    func preparePlay() {
        
        self.baseComposition = compositionBuilder.buildComposition()
        playerItem = self.baseComposition?.makePlayable()
        
        if let player = self.player {
            player.replaceCurrentItem(with: playerItem)
        }
        else {
            self.player = AVPlayer.init(playerItem: playerItem)
        }
        
        if let player = self.player {
            playbackView.prepare(player: player)
        }
        
        self.playerItem?.addObserver(self, forKeyPath: Keys.statusKeyPath, options: .new, context: nil)
        
    }
        
    override func viewDidLayoutSubviews() {
        
        super.viewDidLayoutSubviews()
        
        self.backBtn.frame = CGRect(x: UI.backBtnLeftMargin, y: UI.backBtnTopMargin, width: UI.backBtnSize.width, height: UI.backBtnSize.height)
        
        self.exportBtn.frame = CGRect(x: UIScreen.main.bounds.width - UI.exportBtnSize.width - UI.exportBtnRightMargin, y: UI.exportBtnTopMargin, width: UI.exportBtnSize.width, height: UI.exportBtnSize.height)
        
        
    }
    
    // MARK: - Observer
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if keyPath == Keys.statusKeyPath {
            
            DispatchQueue.main.async {
            
                let status : AVPlayerItem.Status
                
                if let statusNumber = change?[.newKey] as? NSNumber {
                    status = AVPlayerItem.Status(rawValue: statusNumber.intValue) ?? .unknown
                }
                else {
                    status = .unknown
                }
                
                if status == AVPlayerItem.Status.readyToPlay {
                    
                    self.player?.play()
                    
                }
                
            }
                        
        }
        
    }
    
    // MARK: - Private
    
    func loadVideoItems() {
        
        var videoItems : [LMMediaItem] = []
        for i in 0..<segments {
            let url = pathForAsset(with: "\(i).mov")
            let videoItem = LMMediaItem(url: url, mediaType: AVMediaType.video)
            videoItem.prepare { (prepare) in
                
            }
            videoItems.append(videoItem)
        }
        
        compositionBuilder.videos = videoItems
        
    }
    
    func loadVoiceItems() {
        
        var voiceItems : [LMMediaItem] = []
        for i in 0..<segments {
            let url = pathForAsset(with: "\(i).m4a")
            let voiceItem = LMMediaItem(url: url, mediaType: AVMediaType.audio)
            voiceItem.prepare { (prepare) in
                
            }
            voiceItems.append(voiceItem)
        }
        
        compositionBuilder.voices = voiceItems
        
    }
    
    func pathForAsset(with name: String) -> URL {
        let dirUrl = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("videoclips")
        if !FileManager.default.fileExists(atPath: dirUrl.path) {
           try? FileManager.default.createDirectory(at: dirUrl, withIntermediateDirectories: true, attributes: nil)
        }
        return dirUrl.appendingPathComponent(name)
    }
    
    // MARK: - Action
    @objc func backBtnClicked() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func exportBtnClicked() {
        
        guard let baseCompos = self.baseComposition else {
            return
        }
        
        self.exporter = LMCompositionExporter(composition: baseCompos)
        self.exporter?.beginExport()
        
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
