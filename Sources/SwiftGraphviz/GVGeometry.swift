//
//  GVGeometry.swift
//  SwiftGraphviz
//
//  Cross-platform geometry types replacing CoreGraphics dependencies.
//

// Explicit libm import for sin/cos/atan2 rather than relying on them leaking
// through the GraphvizBridge C module (which is fragile across toolchains/targets).
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#elseif canImport(WASILibc)
import WASILibc
#endif
import GraphvizBridge

// MARK: - GVPoint

public struct GVPoint: Equatable, Hashable, Sendable {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    public static let zero = GVPoint(x: 0, y: 0)

    public init(gvPoint: pointf_s) {
        self.init(x: gvPoint.x, y: gvPoint.y)
    }

    public func distance(to other: GVPoint) -> Double {
        let dx = other.x - x
        let dy = other.y - y
        return (dx * dx + dy * dy).squareRoot()
    }

    public var isFinite: Bool {
        x.isFinite && y.isFinite
    }

    public var rounded: GVPoint {
        GVPoint(x: x.rounded(), y: y.rounded())
    }

    public func convertZeroToNil(precision: Double = 0.1) -> GVPoint? {
        distance(to: .zero) < precision ? nil : self
    }

    public func shift(_ dx: Double, _ dy: Double) -> GVPoint {
        GVPoint(x: x + dx, y: y + dy)
    }

    public func interpolate(to other: GVPoint, distance t: Double) -> GVPoint {
        GVPoint(x: (1 - t) * x + t * other.x, y: (1 - t) * y + t * other.y)
    }

    public static func + (lhs: GVPoint, rhs: GVPoint) -> GVPoint {
        GVPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }

    public static func - (lhs: GVPoint, rhs: GVPoint) -> GVPoint {
        GVPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }

    public static func / (lhs: GVPoint, rhs: Double) -> GVPoint {
        GVPoint(x: lhs.x / rhs, y: lhs.y / rhs)
    }
}

// MARK: - GVSize

public struct GVSize: Equatable, Hashable, Sendable {
    public var width: Double
    public var height: Double

    public init(width: Double, height: Double) {
        self.width = width
        self.height = height
    }

    public static let zero = GVSize(width: 0, height: 0)

    public init(gvPoint: pointf_s) {
        self.init(width: gvPoint.x, height: gvPoint.y)
    }

    public var area: Double {
        width * height
    }

    public var isFinite: Bool {
        width.isFinite && height.isFinite
    }

    public func convertZeroToNil(precision: Double = 0.1) -> GVSize? {
        area < precision ? nil : self
    }

    public func hasAtLeastSize(_ minSize: GVSize) -> Bool {
        width >= minSize.width && height >= minSize.height
    }

    public func restrictTo(maxSize: GVSize) -> GVSize {
        GVSize(width: min(width, maxSize.width), height: min(height, maxSize.height))
    }
}

// MARK: - GVRect

public struct GVRect: Equatable, Hashable, Sendable {
    public var origin: GVPoint
    public var size: GVSize

    public init(origin: GVPoint, size: GVSize) {
        self.origin = origin
        self.size = size
    }

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.origin = GVPoint(x: x, y: y)
        self.size = GVSize(width: width, height: height)
    }

    public static let zero = GVRect(origin: .zero, size: .zero)

    public init(midPoint: GVPoint, size: GVSize) {
        self.origin = GVPoint(x: midPoint.x - size.width / 2, y: midPoint.y - size.height / 2)
        self.size = size
    }

    public init(box: boxf) {
        self.init(x: box.LL.x, y: box.LL.y, width: box.UR.x - box.LL.x, height: box.UR.y - box.LL.y)
    }
}

// MARK: - GVVector

public struct GVVector: Equatable, Hashable, Sendable {
    public var dx: Double
    public var dy: Double

    public init(dx: Double, dy: Double) {
        self.dx = dx
        self.dy = dy
    }

    public static let zero = GVVector(dx: 0, dy: 0)

    public init(from: GVPoint, to: GVPoint) {
        self.init(dx: to.x - from.x, dy: to.y - from.y)
    }

    public func length() -> Double {
        (dx * dx + dy * dy).squareRoot()
    }

    public func normalized() -> GVVector {
        let len = length()
        return len > 0 ? self / len : .zero
    }

    public var angle: Double {
        atan2(dy, dx)
    }

    public var orthogonalVector: GVVector {
        GVVector(dx: dy, dy: -dx)
    }

    public var opposingVector: GVVector {
        GVVector(dx: -dx, dy: -dy)
    }

    public func turn(degree: Double) -> GVVector {
        let s = sin(degree)
        let c = cos(degree)
        return GVVector(dx: c * dx - s * dy, dy: s * dx + c * dy)
    }

    public static func + (lhs: GVVector, rhs: GVVector) -> GVVector {
        GVVector(dx: lhs.dx + rhs.dx, dy: lhs.dy + rhs.dy)
    }

    public static func - (lhs: GVVector, rhs: GVVector) -> GVVector {
        GVVector(dx: lhs.dx - rhs.dx, dy: lhs.dy - rhs.dy)
    }

    public static func * (lhs: GVVector, rhs: Double) -> GVVector {
        GVVector(dx: lhs.dx * rhs, dy: lhs.dy * rhs)
    }

    public static func / (lhs: GVVector, rhs: Double) -> GVVector {
        GVVector(dx: lhs.dx / rhs, dy: lhs.dy / rhs)
    }
}

// MARK: - Free functions

public func convertZeroPointToNil(_ point: GVPoint, precision: Double = 0.1) -> GVPoint? {
    point.convertZeroToNil(precision: precision)
}

public func pointTransformToGVPoint(_ point: pointf_s) -> GVPoint {
    GVPoint(gvPoint: point)
}

public func midPoint(between a: GVPoint, and b: GVPoint) -> GVPoint {
    (a + b) / 2
}
