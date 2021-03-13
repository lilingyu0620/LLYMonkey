//
//  LMTimelineItem.swift
//  LLYMonkey
//
//  Created by lly on 2021/2/18.
//  Copyright © 2021 lly. All rights reserved.
//

import UIKit
import CoreMedia

class LMTimelineItem: NSObject {
    
    var timeRange : CMTimeRange
    var startTimeInTimeline : CMTime
    
    init(timeRange : CMTimeRange, startTimeInTimeline : CMTime) {
                
        self.timeRange = timeRange
        self.startTimeInTimeline = startTimeInTimeline
                
    }

}
