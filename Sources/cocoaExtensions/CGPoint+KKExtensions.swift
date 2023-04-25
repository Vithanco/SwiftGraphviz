//
//  CGPoint+KKExtensions.swift
//  QVisual Thinking
//
//  Created by Klaus Kneupner on 19/9/16.
//  Copyright © 2016 Klaus Kneupner. All rights reserved.
//

import Foundation

public extension CGPoint {
    func shift(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        return CGPoint(x: self.x + x, y: self.y + y)
    }

    func shift(_ dir: CGVector) -> CGPoint {
        return CGPoint(x: self.x + dir.dx, y: self.y + dir.dy)
    }
    
    func substract(_ dir: CGPoint) -> CGPoint {
        return CGPoint(x: self.x - dir.x, y: self.y - dir.y)
    }

    var flipped: CGPoint {
        return CGPoint(x: self.y, y: self.x)
    }
	
    func interpolate(to: CGPoint, distance: CGFloat) -> CGPoint {
        let x = CGFloat(1 - distance) * self.x + CGFloat(distance) * to.x
        let y = CGFloat(1 - distance) * self.y + CGFloat(distance) * to.y
        return CGPoint(x: x, y: y)
    }
    
    func interpolateAndOrthoVector(to: CGPoint, distance: CGFloat) -> (CGPoint, CGVector) {
        let x = CGFloat(1 - distance) * self.x + CGFloat(distance) * to.x
        let y = CGFloat(1 - distance) * self.y + CGFloat(distance) * to.y
        return (CGPoint(x: x, y: y), CGVector(from: self,to: to).orthogonalVector) //.normalized())
    }
    
	func distance(to: CGPoint)-> CGFloat {
        let xDist: CGFloat = to.x - self.x
        let yDist: CGFloat = to.y - self.y
        return CGFloat(sqrt((xDist * xDist) + (yDist * yDist)))
    }
    
    var isFinite: Bool {
        return x.isFinite && y.isFinite
    }
    
    var makeNegative: CGPoint {
        return CGPoint(x: -1.0 * self.x, y: -1.0 * self.y)
    }
    var asVector: CGVector {
        return CGVector(dx: x, dy: y)
    }
    
    func orderByDistance(set: Set<CGPoint>) -> [CGPoint] {
        return self.orderByDistance(points: set.asArray)
    }
    
    func orderByDistance(points: [CGPoint]) -> [CGPoint] {
        return points.sorted(by: {a, b in return self.distance(to: a) > self.distance(to: b)})
    }
    
    func orderByDistance(_ a : CGPoint, _ b: CGPoint) -> (CGPoint, CGPoint) {
        return self.distance(to: a) > self.distance(to: b) ? (b, a) : (a, b)
    }

    static func / (left: CGPoint, right: CGFloat) -> CGPoint {
        return CGPoint(x: left.x / right, y: left.y / right)
    }
    
    static func / (left: CGPoint, right: Int) -> CGPoint {
        return left / CGFloat(right)
    }
    
    func convertZeroPointToNil(precision: CGFloat = 0.1) -> CGPoint? {
        if self.distance(to: NSZeroPoint) < precision {
            return nil
        }
        return self
    }
    
    init (gvPoint: pointf_s) {
        self.init(x: CGFloat(gvPoint.x), y: CGFloat(gvPoint.y))
        assert (isFinite)
    }
//
//    static var zero: CGPoint {
//        return CGPoint(x: 0, y: 0)
//    }
    var rounded: CGPoint {
        return CGPoint(x: self.x.rounded(), y: self.y.rounded())
    }
    
}


// needed as parameter in some conversions, so I keep the extra function
func pointTransformGraphvizToCGPoint(_ point: pointf_s) -> CGPoint {
    return CGPoint(gvPoint: point)
}

 extension CGPoint : Hashable {
    public  func hash(into hasher: inout Hasher){
        hasher.combine(x)
        hasher.combine(y)
    }
}
//
//func ==(lhs: CGPoint, rhs: CGPoint) -> Bool {
//    return lhs.distance(to: rhs) < 0.000001 //CGPointEqualToPoint(lhs, rhs)
//}




public func + (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

public func - (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

/***
 * Adds a vector to a point and returns new point
 */
public func + (left: CGPoint, right: CGVector) -> CGPoint {
    return CGPoint(x: left.x + right.dx, y: left.y + right.dy)
}

func convertZeroPointToNil(_ gvPos: CGPoint, precision: CGFloat = 0.1) -> CGPoint? {
    return gvPos.convertZeroPointToNil(precision:precision)
}

public func midPoint(between: CGPoint, and: CGPoint) -> CGPoint{
    return (between + and) / 2
}
