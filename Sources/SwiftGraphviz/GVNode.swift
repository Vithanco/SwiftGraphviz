//
//  GVNode.swift
//  Vithanco
//
//  Created by Klaus Kneupner on 15/01/2019.
//  Copyright © 2019 Klaus Kneupner. All rights reserved.
//

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#endif
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

    public var pos: GVPoint {
        let s = nd_coord(self)
        return GVPoint(gvPoint: s)
    }

    /// Node width as returned by Graphviz (in inches).
    public var widthInches: GVInches {
        return GVInches(nd_width(self))
    }

    /// Node height as returned by Graphviz (in inches).
    public var heightInches: GVInches {
        return GVInches(nd_height(self))
    }

    /// Node width converted to screen points.
    public var width: GVPoints {
        return widthInches.asPoints
    }

    /// Node height converted to screen points.
    public var height: GVPoints {
        return heightInches.asPoints
    }

    public var size: GVSize {
        return GVSize(width: width.value, height: height.value)
    }

    public var rect: GVRect {
        let mid = self.pos
        let w = self.width.value
        let h = self.height.value
        return GVRect(midPoint: mid, size: GVSize(width: w, height: h))
    }

}
