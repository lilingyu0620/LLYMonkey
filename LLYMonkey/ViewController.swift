//
//  ViewController.swift
//  LLYMonkey
//
//  Created by lly on 2020/7/18.
//  Copyright © 2020 lly. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    let recordView = LMRecordView(frame: UIScreen.main.bounds)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        recordView.finishBlock = { [weak self] (isFinish,segments) in
            if isFinish {
                guard let ws = self else { return }
                let previewVC = LMPreviewViewController()
                previewVC.modalPresentationStyle = .fullScreen
                previewVC.segments = segments
                ws.present(previewVC, animated: true, completion: nil)
            }
        }
        
        setupUI()
        
    }

    func setupUI() {
        
        view.addSubview(recordView)
        
    }
    
    override func viewDidLayoutSubviews() {
        
        super.viewDidLayoutSubviews()
        
        recordView.frame = view.bounds
        
    }
}

extension ViewController {
    
    override func motionBegan(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        LMAirSandbox.shared.show()
    }
    
}

