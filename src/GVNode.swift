//
//  GVNode.swift
//  Vithanco
//
//  Created by Klaus Kneupner on 15/01/2019.
//  Copyright © 2019 Klaus Kneupner. All rights reserved.
//

import Foundation


public typealias GVNode = UnsafeMutablePointer<Agnode_t>


public extension UnsafeMutablePointer where Pointee == Agnode_t {

    var pos : CGPoint {
        let s = nd_coord(self)
        return CGPoint(gvPoint: s)
    }
    var width : CGFloat {
        let s = nd_width(self)
        return CGFloat(s) * pointsPerInch
    }
    var height : CGFloat {
        let s = nd_height(self)
        return CGFloat(s) * pointsPerInch
    }
    var rect : CGRect {
        let mid = self.pos
        let w = self.width
        let h = self.height
        return CGRect(middlePoint: mid, size: CGSize(width: w, height: h))
    }

}
