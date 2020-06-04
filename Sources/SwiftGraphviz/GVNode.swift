//
//  GVNode.swift
//  Vithanco
//
//  Created by Klaus Kneupner on 15/01/2019.
//  Copyright © 2019 Klaus Kneupner. All rights reserved.
//

import Foundation


public typealias GVNode = UnsafeMutablePointer<Agnode_t>

extension UnsafeMutablePointer where Pointee == Agnode_t  {

    public var pos : CGPoint {
        let s = nd_coord(self)
        return CGPoint(gvPoint: s)
    }
    public var width : CGFloat {
        let s = nd_width(self)
        return CGFloat(s) * pointsPerInch
    }
    public var height : CGFloat {
        let s = nd_height(self)
        return CGFloat(s) * pointsPerInch
    }
    
    public var size: CGSize {
        return CGSize(width: width, height: height)
    }
    
    public var rect : CGRect {
        let mid = self.pos
        let w = self.width
        let h = self.height
        return CGRect(midPoint: mid, size: CGSize(width: w, height: h))
    }
    
}

extension CGRect{
    init(midPoint: CGPoint, size: CGSize) {
        self.init(x: midPoint.x - size.width / 2, y: midPoint.y - size.height / 2, width: size.width, height: size.height)
    }
}
