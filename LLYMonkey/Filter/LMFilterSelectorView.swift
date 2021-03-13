//
//  LMFilterSelectorView.swift
//  LLYMonkey
//
//  Created by lly on 2021/2/19.
//  Copyright © 2021 lly. All rights reserved.
//

import UIKit

class LMFilterSelectorView: UIView {

    lazy var scrollView : UIScrollView = {
        let scrollView = UIScrollView(frame: .zero)
        scrollView.backgroundColor = .clear
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.isPagingEnabled = true
        return scrollView
    }()
    
    lazy var leftButton : UIButton = {
        let btn = UIButton(frame: CGRect(x: 20, y: 0, width: 40, height: 60))
        btn.backgroundColor = .clear
        btn.addTarget(self, action: #selector(leftBtnClicked), for: .touchUpInside)
        btn.setImage(UIImage.init(named: "left_arrow"), for: .normal)
        return btn
    }()
    
    lazy var rightButton : UIButton = {
        let btn = UIButton(frame: CGRect(x: UIScreen.main.bounds.width - 40 - 20, y: 0, width: 40, height: 60))
        btn.backgroundColor = .clear
        btn.addTarget(self, action: #selector(rightBtnClicked), for: .touchUpInside)
        btn.setImage(UIImage.init(named: "right_arrow"), for: .normal)
        return btn
    }()
    
    var labels : [UILabel] = []
    
    var activityLabel : UILabel?
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        
        setupUI()
        
        setupLabels()
        
        setupActions()
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        
        self.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        
        addSubview(scrollView)
        
        addSubview(leftButton)
        
        addSubview(rightButton)
        
    }
    
    override func layoutSubviews() {
        
        super.layoutSubviews()
        
        scrollView.frame = self.bounds
        
    }
    
    func setupLabels() {
        
        let filterNames = LMPhotoFilters.shared.fliterDisplayNames()
        var frame = self.bounds
        for name in filterNames {
            let label = UILabel(frame: frame)
            label.backgroundColor = .clear
            label.font = UIFont.boldSystemFont(ofSize: 20)
            label.textColor = .white
            label.textAlignment = .center
            label.text = name
            self.scrollView.addSubview(label)
            frame.origin.x += frame.size.width
            self.labels.append(label)
        }
        
        self.activityLabel = self.labels.first
        
        let width = frame.size.width * CGFloat(filterNames.count)
        self.scrollView.contentSize = CGSize(width: width, height: frame.size.height)
        
    }
    
    func setupActions() {
        
        self.leftButton.isEnabled = false
        
    }
    
    // MARK: - Action
    
    @objc func leftBtnClicked() {
        
        let labelIndex = self.labels.firstIndex(of: self.activityLabel!)
        
        if let index = labelIndex {
         
            if index > 0 {
                
                let label = self.labels[index-1]
                self.scrollView.scrollRectToVisible(label.frame, animated: true)
                self.activityLabel = label
                self.rightButton.isEnabled = true
                
                postFilterChancge(filterName: label.text!)
                
            }
            
            self.leftButton.isEnabled = (index - 1) > 0
            
        }
        
    }
    
    @objc func rightBtnClicked() {
        
        let labelIndex = self.labels.firstIndex(of: self.activityLabel!)
        if let index = labelIndex {
            
            if index < self.labels.count - 1 {
                
                let label = self.labels[index+1]
                self.scrollView.scrollRectToVisible(label.frame, animated: true)
                self.activityLabel = label
                self.leftButton.isEnabled = true
                
                postFilterChancge(filterName: label.text!)
                
            }
            
            self.rightButton.isEnabled = index < (self.labels.count - 1 - 1)
        }
        
    }
    
    func postFilterChancge(filterName : String) {
        let filter = LMPhotoFilters.shared.filterWithName(filterName: filterName)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: LMPhotoFilters.FilterChangeNotification), object: filter)
    }
    
}
