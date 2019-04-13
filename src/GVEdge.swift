//
//  GVEdge.swift
//  Vithanco
//
//  Created by Klaus Kneupner on 13/01/2019.
//  Copyright © 2019 Klaus Kneupner. All rights reserved.
//

import Foundation
import AppKit

public typealias GVEdge = UnsafeMutablePointer<Agedge_t>

extension UnsafeMutablePointer where Pointee == Agedge_t {
    
    
    var labelPos: CGPoint? { //lp
        if let lPos = ed_lp(self) {
            return convertZeroPointToNil(CGPoint(gvPoint: lPos.pointee))
        }
        return nil
    }
    var headLabelPos:CGPoint? {
        if let lPos = ed_head_lp(self) {
            return convertZeroPointToNil(CGPoint(gvPoint: lPos.pointee))
        }
        return nil
    }
    var tailLabelPos:CGPoint? {
        if let lPos = ed_tail_lp(self) {
            return convertZeroPointToNil(CGPoint(gvPoint: lPos.pointee))
        }
        return nil
    }
    
    var labelText: String? {
        if let text = ed_label_text(self) {
            return String(cString: text)
        }
        return nil
    }
    
    var headLabelText: String? {
        if let text = ed_head_label_text(self) {
            return String(cString: text)
        }
        return nil
    }
    
    var tailLabelText: String? {
        if let text = ed_tail_label_text(self) {
            return String(cString: text)
        }
        return nil
    }
    
    var spline: GVSplines? {
        guard let t = pointee.base.data else {
            return nil
        }
        guard let spline = t.withMemoryRebound(to: Agedgeinfo_t.self, capacity: 1, {return $0.pointee.spl})  else {
            return nil
        }
        if spline.pointee.size != 1 {
            logThis(.warning, "an edge with size == \(spline.pointee.size)")
        }
        return spline
    }
    
    func getPath () throws -> [CGPoint]  {
        guard let spline = spline, let bezier = spline.pointee.list else {  //warning! this could be an array, see warning log before
            throw GraphvizError.noPath
        }
        let nrPoints = Int(bezier.pointee.size)
        let pointer = UnsafeRawPointer(bezier.pointee.list).bindMemory(to: pointf_s.self, capacity: nrPoints)
        var points: [pointf_s] = []
        for i in 0..<nrPoints {
            points.append(pointer[i])
        }
        return points.map(pointTransformGraphvizToCGPoint)
    }
    
    var arrowHead: CGPoint? {
        guard let spline = spline, let bezier = spline.pointee.list else {
            fatalError()
            
        }
        let result = bezier.pointee.ep
        return convertZeroPointToNil(pointTransformGraphvizToCGPoint(result))
    }
    
    var arrowTail: CGPoint? {
        guard let spline = spline, let bezier = spline.pointee.list else {
            fatalError()
        }
        let result = bezier.pointee.sp
        return convertZeroPointToNil(pointTransformGraphvizToCGPoint(result))
    }
    
    var headPortPos: CGPoint {
        return pointTransformGraphvizToCGPoint(ed_headPort_pos(self))
    }
    
    var tailPortPos: CGPoint {
        return pointTransformGraphvizToCGPoint(ed_tailPort_pos(self))
    }
    
}

struct GVEdgeEndingData {
    fileprivate var _pos: CGPoint
    var pos : CGPoint {
        return _pos
    }
    var type : GVEdgeEnding
    var path : NSBezierPath
    
    mutating func transform(using: AffineTransform) {
//        assert(path.bounds.expandRect(1).contains(pos),"path.bounds: \(path.bounds), pos: \(pos)")
        let trans = NSAffineTransform(transform: using)
        _pos = trans.transform(pos)
        path = trans.transform(path)
        assert(path.bounds.expandRect(1).contains(pos),"path.bounds: \(path.bounds), pos: \(pos)")
    }
    
    mutating func transform(by: CGVector) {
        transform(using: AffineTransform(translationByX: by.dx, byY: by.dy))
//        assert(path.bounds.expandRect(1).contains(pos),"path.bounds: \(path.bounds), pos: \(pos)")
//        _pos = pos.shift(by)
//        path.transform(using: )
//
//        assert(path.bounds.expandRect(1).contains(pos),"path.bounds: \(path.bounds), pos: \(pos)")
    }
    func transformed(by: CGVector) -> GVEdgeEndingData{
        let newPos = pos.shift(by)
        let newPath = NSAffineTransform(transform: AffineTransform(translationByX: by.dx, byY: by.dy)).transform(path)
        return GVEdgeEndingData(pos: newPos,type: type, path: newPath)
    }
    
    init(pos : CGPoint, type : GVEdgeEnding, path : NSBezierPath){
        self._pos = pos
        self.type = type
        self.path = path
        
        assert(path.bounds.expandRect(1).contains(pos),"path.bounds: \(path.bounds), pos: \(pos)")
    }

    init(pos: CGPoint, type: GVEdgeEnding, otherPoint: CGPoint) {
        self._pos = pos
        self.type = type
        
        var secondPos = otherPoint
        let distance = pos.distance(to: otherPoint)
//        Swift.print("distance: \(distance)")
        
        //        if otherPoint.distance(to: pos) < 0.1 {
        //            path = NSBezierPath(circleAt: otherPoint, radius: 6)
        //            return
        //        }
        switch type {
            //        case .none:
        //            path = NSBezierPath(circleAt: pos, radius: 6)
        case .normal :
            //            if otherPoint.distance(to: pos) > 10 {
            //                Swift.print("\(pos) - \(type.graphvizName) - \(otherPoint), distance: \(otherPoint.distance(to: pos))")
            //            }
            if pos.distance(to: otherPoint) > 10 {
                secondPos = pos + CGVector(from: pos, to: secondPos).normalized() * CGFloat(10.0)
            }
            path = NSBezierPath(arrowHeadWithStartPoint: secondPos, endPoint: pos, tailWidth: 2, headWidth: 8, headLength: secondPos.distance(to: pos))
        case .dot, .none:
            if pos.distance(to: otherPoint) > 10 {
                secondPos = pos + CGVector(from: pos, to: secondPos).normalized() * CGFloat(8.0)
            }
            path = NSBezierPath(circleBetween: pos, and: secondPos)
        case  .diamond:
            if pos.distance(to: otherPoint) > 10 {
                secondPos = pos + CGVector(from: pos, to: secondPos).normalized() * CGFloat(10.0)
            }
            path = NSBezierPath(diamondBetween: pos, and: secondPos)
        }
        assert (path.bounds.size.area > 0)
        assert(path.bounds.expandRect(1).contains(pos), "path.bounds: \(path.bounds), pos: \(pos)")
    }
}

extension CGSize {
    fileprivate var area: CGFloat {
        return self.width * self.height
    }
}

//let emptyEdgeEnding = GVEdgeEndingData(pos: NSZeroPoint, type: .none, path: NSBezierPath())

class GVEdgePosData : NSObject {
    
    var head: GVEdgeEndingData
    var tail: GVEdgeEndingData
    var isSuggested: Bool // is this edge suggested by NodeType
    var path = NSBezierPath()
    var outerPath: NSBezierPath  // for hit testing of edge. as well used for graphics
    var gvEdge: GVEdge?
    
    // see https://stackoverflow.com/questions/1165647/how-to-determine-if-a-list-of-polygon-points-are-in-clockwise-order/1180256#1180256
    var shoeLaceComponent: CGFloat
    
    var labelPos: CGPoint?
    
    init( gvEdge: GVEdge, headNode: CGPoint, tailNode: CGPoint, headEnding: GVEdgeEnding, tailEnding: GVEdgeEnding, isSuggested: Bool) throws {
        self.gvEdge = gvEdge
        var cgPath = try gvEdge.getPath()
        
        self.isSuggested = isSuggested
        self.labelPos = gvEdge.labelPos
        self.shoeLaceComponent = (headNode.x - tailNode.x) * (headNode.y + tailNode.y)
        
        guard var head = gvEdge.arrowHead, var tail = gvEdge.arrowTail else {
            fatalError()
        }
        
        let wrongDirection = tailNode.distance(to: head) < tailNode.distance(to: tail)
        var hasHead = headEnding != .none
        var hasTail = tailEnding != .none
        if wrongDirection {
            let switchValues = hasHead
            hasHead = hasTail
            hasTail = switchValues
        }
        
        var startPath = cgPath[0]
        var endPath = cgPath[cgPath.count-1]
        
        //it doesn't matter wether the path has the right direction or not, just paint it in the order provided
    
        if hasTail {
            path.move(to: startPath)
        } else {
            path.move(to: tail)
            path.line(to: startPath)
        }
        for i in stride(from: 1, to: cgPath.count, by: 3) {
            path.curve(to: cgPath[i + 2], controlPoint1: cgPath[i], controlPoint2: cgPath[i + 1])
        }
        if !hasHead {
            path.line(to: head)
        }
        
        if wrongDirection {
            // Graphviz got it wrong, fix order
            let switchPoint = tail
            tail =  head
            head = switchPoint
            endPath = cgPath[0]
            startPath = cgPath[cgPath.count-1]
        }
        
        self.shoeLaceComponent = (head.x - tail.x) * (head.y + tail.y)
        
        
        self.head = GVEdgeEndingData(pos: head, type: headEnding, otherPoint: endPath)
        self.tail = GVEdgeEndingData(pos: tail, type: tailEnding, otherPoint: startPath)
        
        outerPath = NSBezierPath(path: path.outerPath)
    }
    
    
    //    init(edge: GVEdge, head: GVEdgeEnding, tail: GVEdgeEnding, isSuggested: Bool) {
    //        gvEdge = edge
    //        var cgPath = edge.path
    //
    //        self.isSuggested = isSuggested
    //        self.labelPos = edge.labelPos
    //
    //        path.move(to: cgPath[0])
    //        for i in stride(from: 1, to: cgPath.count, by: 3) {
    //            path.curve(to: cgPath[i + 2], controlPoint1: cgPath[i], controlPoint2: cgPath[i + 1])
    //        }
    //        let start = cgPath[0]
    //        let end = cgPath[cgPath.count-1]
    //
    //        var arrowHead = edge.arrowHead ?? end
    //        var arrowTail = edge.arrowTail ?? start
    //
    //        let closeToHead = arrowHead.distance(to: start) < arrowHead.distance(to: end) ? start : end
    //        let closeToTail = arrowTail.distance(to: start) < arrowTail.distance(to: end) ? start : end
    //
    //        self.head = GVEdgeEndingData(pos: arrowHead, type: head, otherPoint: closeToHead)
    //        self.tail = GVEdgeEndingData(pos: arrowTail, type: tail, otherPoint: closeToTail)
    //
    //        outerPath = NSBezierPath(path: path.outerPath)
    //    }
    //
//    override init() {
//        //        path = [NSZeroPoint]
//        head = emptyEdgeEnding
//        tail = emptyEdgeEnding
//        outerPath = NSBezierPath()
//        isSuggested = true
//        super.init()
//    }
    
    func shift(by: CGVector){
        let affineT = AffineTransform(translationByX: by.dx, byY: by.dy)
        path.transform(using: affineT)
        outerPath.transform(using: affineT)
        if let lbl = labelPos {
            labelPos = lbl.shift(by.dx, by.dy)
        }
        head = head.transformed(by: by)
        tail = tail.transformed(by: by)
    }
}
