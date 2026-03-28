//
//  GVNode.swift
//  Vithanco
//
//  Created by Klaus Kneupner on 15/01/2019.
//  Copyright © 2019 Klaus Kneupner. All rights reserved.
//

import Foundation
import GraphvizBridge


public typealias GVNode = UnsafeMutablePointer<Agnode_t>

extension UnsafeMutablePointer where Pointee == Agnode_t {

    // MARK: - Attribute helpers

    /// Set a node attribute value.
    public func set(_ param: GVNodeParameters, _ value: String) {
        let cName = strdup(param.rawValue)
        let cVal = strdup(value)
        agset(self, cName, cVal)
        free(cName)
        free(cVal)
    }

    // MARK: - Layout results

    public var pos: CGPoint {
        let s = nd_coord(self)
        return CGPoint(gvPoint: s)
    }

    /// Node width as returned by Graphviz (in inches).
    public var widthInches: GVInches {
        return GVInches(CGFloat(nd_width(self)))
    }

    /// Node height as returned by Graphviz (in inches).
    public var heightInches: GVInches {
        return GVInches(CGFloat(nd_height(self)))
    }

    /// Node width converted to screen points.
    public var width: GVPoints {
        return widthInches.asPoints
    }

    /// Node height converted to screen points.
    public var height: GVPoints {
        return heightInches.asPoints
    }

    public var size: CGSize {
        return CGSize(width: width.value, height: height.value)
    }

    public var rect: CGRect {
        let mid = self.pos
        let w = self.width.value
        let h = self.height.value
        return CGRect(midPoint: mid, size: CGSize(width: w, height: h))
    }

}

extension CGRect {
    init(midPoint: CGPoint, size: CGSize) {
        self.init(x: midPoint.x - size.width / 2, y: midPoint.y - size.height / 2, width: size.width, height: size.height)
    }
}
