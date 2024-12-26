//
//  File.swift
//  
//
//  Created by Gifton Okoronkwo on 12/26/24.
//

import Foundation

extension Int {
    var seconds: TimeInterval {
        TimeInterval(self)
    }
    
    var minutes: TimeInterval {
        TimeInterval(self * 60)
    }
    
    var hours: TimeInterval {
        TimeInterval(self * 60 * 60)
    }
    
    var days: TimeInterval {
        TimeInterval(self * 60 * 60 * 24)
    }
}


extension Int {
    var thousand: Int { self * 1000 }
    var million: Int { self * 1_000_000 }
}
