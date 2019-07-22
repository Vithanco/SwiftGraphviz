//
//  CGSize+KKExtensions.swift
//  SwiftGraphvizIOS
//
//  Created by Klaus Kneupner on 22/07/2019.
//  Copyright © 2019 Klaus Kneupner. All rights reserved.
//

import Foundation

extension CGSize {
    var isFinite: Bool {
        return width.isFinite && height.isFinite
    }
    
    init (gvPoint: pointf_s) {
        self.init(width: CGFloat(gvPoint.x), height: CGFloat(gvPoint.y))
        assert (isFinite)
    }
    
    func convertZeroSizeToNil(precision: CGFloat = 0.1) -> CGSize? {
        if self.area < precision {
            return nil
        }
        return self
    }
    
    var area: CGFloat {
        return width * height
    }
}


func convertZeroSizeToNil(_ gvSize: CGSize, precision: CGFloat = 0.1) -> CGSize? {
    return gvSize.convertZeroSizeToNil(precision:precision)
}
