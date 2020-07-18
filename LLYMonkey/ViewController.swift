//
//  ViewController.swift
//  LLYMonkey
//
//  Created by lly on 2020/7/18.
//  Copyright © 2020 lly. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    let recordView = LMRecordView(frame: .zero)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
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

