//
//  GVEdge.swift
//  SwiftGraphiz
//
//  Created by Klaus Kneupner on 13/01/2019.
//  Copyright © 2019 Klaus Kneupner. All rights reserved.
//

import Foundation

public protocol EdgeLayout {
    var path: CGPath {get}
    var labelPos: CGPoint? {get}
    var headLabelPos:CGPoint? {get}
    var tailLabelPos:CGPoint? {get}
    
    /// the head is between arrowHead2 -> arrowHead
    var arrowHead: CGPoint {get}
    /// the head is between arrowHead2 -> arrowHead
    var arrowHead2: CGPoint {get}
    
    /// the tail is between arrowTail -> arrowTail2
    var arrowTail: CGPoint {get}
    /// the tail is between arrowTail -> arrowTail2
    var arrowTail2: CGPoint {get}
    
    func fixDirection(tailNode: CGPoint) -> EdgeLayout
}

extension EdgeLayout {
    func fixDirection(tailNode: CGPoint) -> EdgeLayout {
        let wrongDirection = tailNode.distance(to: arrowHead) < tailNode.distance(to: arrowTail)
        if wrongDirection {
            return EdgeLayoutImpl(path: path, labelPos: labelPos, headLabelPos: headLabelPos, tailLabelPos: tailLabelPos, arrowHead: arrowTail, arrowTail: arrowHead, arrowHead2: arrowTail2, arrowTail2: arrowHead2)
        }
        return self
    }
}

private struct EdgeLayoutImpl: EdgeLayout {
    let path: CGPath
    let labelPos: CGPoint?
    let headLabelPos: CGPoint?
    let tailLabelPos: CGPoint?
    let arrowHead: CGPoint
    let arrowTail: CGPoint
    let arrowHead2: CGPoint
    let arrowTail2: CGPoint
}
extension EdgeLayoutImpl {
    init(gvEdge: GVEdge) throws {
        self.labelPos = gvEdge.labelPos
        self.headLabelPos = gvEdge.headLabelPos
        self.tailLabelPos = gvEdge.tailLabelPos
        
        guard let head = gvEdge.arrowHead, let tail = gvEdge.arrowTail else {
            throw GraphvizError.headTailMissing
        }
        arrowHead = head
        arrowTail = tail
        
        //it doesn't matter wether the path has the right direction or not, just paint it in the order provided
        let cgPath = try gvEdge.getPath()
        let buildPath = CGMutablePath()
        buildPath.move(to: cgPath[0])

        for i in stride(from: 1, to: cgPath.count, by: 3) {
            buildPath.addCurve(to: cgPath[i + 2], control1: cgPath[i], control2: cgPath[i + 1])
        }
        path = buildPath
        arrowHead2 = cgPath[cgPath.count-1]
        arrowTail2 = cgPath[0]
    }
    
}

public typealias GVEdge = UnsafeMutablePointer<Agedge_t>

public extension UnsafeMutablePointer where Pointee == Agedge_t {
    
    
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
    
    func getPath() throws -> [CGPoint]  {
        guard let spline = spline, let bezier = spline.pointee.list else {  //warning! this could be an array, see warning log in var spine: GVSlines?
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
    
    func asEdgeLayout() throws -> EdgeLayout {
        return try EdgeLayoutImpl(gvEdge: self)
    }
    
    func asEdgeLayoutFixDirection(tailNode: CGPoint) throws -> EdgeLayout {
        return try EdgeLayoutImpl(gvEdge: self).fixDirection(tailNode: tailNode)
    }
}

