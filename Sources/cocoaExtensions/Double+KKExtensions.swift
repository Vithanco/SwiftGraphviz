//
//  Double+KKExtensions.swift
//  Visual Thinking
//
//  Created by Klaus Kneupner on 22/1/17.
//  Copyright © 2017 Klaus Kneupner. All rights reserved.
//

import Foundation


func isDoubleEqual(_ left: Double, _ right: Double, delta: Double = 0.01) -> Bool {
    return fabs(left - right) <= delta
}

func isCGFloatEqual(_ left: CGFloat, _  right: CGFloat, delta: CGFloat = 0.01) -> Bool {
    return abs(left - right) <= delta
}

public extension CGFloat {
    var squared: CGFloat {
        return self*self
    }
    var asDouble: Double {
        return Double(self)
    }
}

  extension Double {
    var asCGFloat: CGFloat {
        return CGFloat(self)
    }
}
