////
////  NSFrame+KKExtensions.swift
////  Visual Thinking
////
////  Created by Klaus Kneupner on 23/4/16.
////  Copyright © 2016 Klaus Kneupner. All rights reserved.
////
//
//import AppKit
//
//public enum VerticalPosition {
//    case top
//    case middle
//    case bottom
//}
//
//public enum HorizontalPosition {
//    case left
//    case oneQuarter
//    case middle
//    case threeQuarters
//    case right
//}
//
// extension CGRect {
//
//    var midPoint: CGPoint {
//        return self.position(.middle, horizontal: .middle)
//    }
////
//    func subRect(_ border: CGFloat) -> CGRect {
//        return self.insetBy(dx: border, dy: border)
////        return NSMakeRect(self.origin.x + border, self.origin.y + border, self.width - 2 * border, self.height - 2 * border)
//    }
//
//    func subRect(inMiddle: CGRect) -> CGRect {
//        return subRect(inMiddleSize: inMiddle.size)
//    }
//
//    func subRect(inMiddleSize: CGSize) -> CGRect {
//        return CGRect(midPoint: self.midPoint, size: inMiddleSize)
//    }
//
//    func subRect(factor: CGFloat) -> CGRect {
//        assert (factor >= 0)
//         assert (factor <= 1)
//        return subRect(inMiddleSize: self.size * factor)
//    }
//
//
//    func expandRect(_ border: CGFloat) -> CGRect {
//        return subRect(-1 * border)
//    }
//
//    func moveMiddleTo(_ point: CGPoint) -> CGRect {
//        return CGRect(midPoint: point, size: self.size)
//    }
//
//    func position(_ vertical: VerticalPosition, horizontal: HorizontalPosition) -> CGPoint {
//        var x: CGFloat
//        var y: CGFloat
//        switch vertical {
//        case .top:
//            y = self.origin.y + self.height
//        case .middle:
//            y = self.origin.y + self.height * 0.5
//        case .bottom:
//            y = self.origin.y
//        }
//        switch horizontal {
//        case .left:
//            x = self.origin.x
//        case .middle:
//            x = self.origin.x + self.width * 0.5
//        case .right:
//            x = self.origin.x + self.width
//        case .oneQuarter:
//            x = self.origin.x + self.width * 0.25
//        case .threeQuarters:
//            x = self.origin.x + self.width * 0.75
//        }
//        return NSMakePoint(x, y)
//    }
//
//    func innerPosition(_ vertical: VerticalPosition, horizontal: HorizontalPosition, distance: CGFloat) -> CGPoint {
//        var x: CGFloat
//        var y: CGFloat
//        switch vertical {
//        case .top:
//            y = self.origin.y + self.height - distance
//        case .middle:
//            y = self.origin.y + self.height * 0.5
//        case .bottom:
//            y = self.origin.y + distance
//        }
//        switch horizontal {
//        case .left:
//            x = self.origin.x + distance
//        case .middle:
//            x = self.origin.x + self.width * 0.5
//        case .right:
//            x = self.origin.x + self.width - distance
//        case .oneQuarter:
//            x = self.origin.x + self.width * 0.25
//        case .threeQuarters:
//            x = self.origin.x + self.width * 0.75
//        }
//        return NSMakePoint(x, y)
//    }
//
//    var top: CGFloat {
//        return origin.y + height
//    }
//
//    var right: CGFloat {
//        return origin.x + width
//    }
//
//    func roundedRectPath(_ radius: CGFloat) -> NSBezierPath {
//        let result = NSBezierPath()
//
//        result.move(to: position(.middle, horizontal: .left))
//        result.appendArc(from: position(.top, horizontal: .left), to: position(.top, horizontal: .middle), radius: radius)
//        result.appendArc(from: position(.top, horizontal: .right), to: position(.middle, horizontal: .right), radius: radius)
//        result.appendArc(from: position(.bottom, horizontal: .right), to: position(.bottom, horizontal: .middle), radius: radius)
//        result.appendArc(from: position(.bottom, horizontal: .left), to: position(.middle, horizontal: .left), radius: radius)
//        result.close()
//
//        return result
//    }
//
//    func path() -> NSBezierPath {
//        let result = NSBezierPath()
//
//        result.move(to: position(.top, horizontal: .left))
//        result.move(to: position(.top, horizontal: .right))
//        result.move(to: position(.bottom, horizontal: .right))
//        result.move(to: position(.bottom, horizontal: .left))
//        result.close()
//
//        return result
//    }
//
//    func partiallyRoundedRectPath(_ radius: CGFloat) -> NSBezierPath {
//        let result = NSBezierPath()
//
//        result.move(to: position(.bottom, horizontal: .left))
//        result.appendArc(from: position(.top, horizontal: .left), to: position(.top, horizontal: .middle), radius: radius)
//        result.appendArc(from: position(.top, horizontal: .right), to: position(.middle, horizontal: .right), radius: radius)
//        result.line(to: position(.bottom, horizontal: .right))
//        result.line(to: position(.bottom, horizontal: .left))
//
//        return result
//    }
//
//    func addToHeight(_ amount: CGFloat) -> NSRect {
//        return NSRect(x: origin.x, y: origin.y, width: size.width, height: size.height + amount)
//    }
//
//    func addToWidth(_ amount: CGFloat) -> NSRect {
//        return NSRect(x: origin.x, y: origin.y, width: size.width + amount, height: size.height )
//    }
//
//    func substractFromHeight(_ amount: CGFloat) -> NSRect {
//        return addToHeight(-1 * amount)
//    }
//
////    init(origin: CGPoint, size: CGSize) {
////        self.init(x: origin.x, y: origin.y, width: size.width, height: size.height)
////    }
//

//
//    /// create a rect that is determined by two opposing corners
//    init(point1: CGPoint, point2: CGPoint){
//        self.init(x: min(point1.x, point2.x), y: min(point1.y, point2.y), width: abs(point1.x - point2.x),height: abs(point1.y - point2.y))
//    }
//
//    func combine(_ other: CGRect) -> CGRect {
//        return self.union(other)
//    }
//
//    func shift(by: CGVector) -> NSRect {
//        return self.offsetBy(dx: by.dx, dy: by.dy)
////        return NSRect(x: self.origin.x + by.x, y: self.origin.y + by.y, width: self.size.width, height: self.size.height)
//    }
//
//    func shift(dx: CGFloat, dy: CGFloat) -> NSRect {
//        return self.offsetBy(dx: dx, dy: dy)
//        //        return NSRect(x: self.origin.x + by.x, y: self.origin.y + by.y, width: self.size.width, height: self.size.height)
//    }
//
//    func drawDottedRoundedRectangle() {
//        let path = NSBezierPath(roundedRect: self, xRadius: 5, yRadius: 5)
//        path.lineWidth = 3
//        var pattern: [CGFloat] = [5.0,2.0]
//
//        path.setLineDash(&pattern, count: 2, phase: 0.0)
//        path.stroke()
//    }
//
//
//    init (box: boxf) {
//        self.init(x: box.LL.x, y: box.LL.y, width: box.UR.x - box.LL.x, height: box.UR.y - box.LL.y)
//    }
//
//
//    func minSized(_ minSize: CGSize) -> CGRect{
//        return minSized(width: minSize.width, height: minSize.height)
//    }
//
//    func minSized(width: CGFloat, height: CGFloat) -> CGRect{
//        return CGRect(midPoint: self.midPoint, size: CGSize(width: max(width, self.width), height: max(height,self.height)))
//    }
//
//    func enlarge(width: CGFloat, height: CGFloat) -> CGRect{
//           return CGRect(midPoint: self.midPoint, size: CGSize(width:  self.width + width, height: self.height + height))
//       }
//
//
//}
