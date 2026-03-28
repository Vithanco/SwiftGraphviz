//
//  GVGeometry+Apple.swift
//  SwiftGraphviz
//
//  CoreGraphics bridging for Apple platforms.
//

#if canImport(CoreGraphics)
import CoreGraphics

public extension GVPoint {
    var cgPoint: CGPoint { CGPoint(x: x, y: y) }
    init(_ cgPoint: CGPoint) { self.init(x: Double(cgPoint.x), y: Double(cgPoint.y)) }
}

public extension GVSize {
    var cgSize: CGSize { CGSize(width: width, height: height) }
    init(_ cgSize: CGSize) { self.init(width: Double(cgSize.width), height: Double(cgSize.height)) }
}

public extension GVRect {
    var cgRect: CGRect { CGRect(x: origin.x, y: origin.y, width: size.width, height: size.height) }
    init(_ cgRect: CGRect) { self.init(x: Double(cgRect.origin.x), y: Double(cgRect.origin.y), width: Double(cgRect.width), height: Double(cgRect.height)) }
}

public extension GVVector {
    var cgVector: CGVector { CGVector(dx: dx, dy: dy) }
    init(_ cgVector: CGVector) { self.init(dx: Double(cgVector.dx), dy: Double(cgVector.dy)) }
}
#endif
