//
//  GVNode.swift
//  Vithanco
//
//  Created by Klaus Kneupner on 15/01/2019.
//  Copyright © 2019 Klaus Kneupner. All rights reserved.
//

import Foundation


public protocol NodeLayout{
    var pos: CGPoint {get}
    var size: CGSize {get}
}

private struct NodeLayoutImpl : NodeLayout {
     let pos: CGPoint
    let size: CGSize
    init(node: GVNode) {
        self.pos = node.pos
        self.size = node.size
    }
}

public extension NodeLayout {
    var rect: CGRect{
        return CGRect(midPoint: self.pos, size: self.size)
    }
}

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
    
    var asNodeLayout: NodeLayout {
        return NodeLayoutImpl (node: self)
    }
}
