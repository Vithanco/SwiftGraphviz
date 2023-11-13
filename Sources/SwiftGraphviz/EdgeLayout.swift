//
//  EdgeLayout.swift
//  SwiftGraphviz
//
//  Created by Klaus Kneupner on 02/09/2023.
//  Copyright © 2023 Klaus Kneupner. All rights reserved.
//

import AppKit
import CoreGraphics


//func asEdgeLayout() throws -> EdgeLayout {
//    return try EdgeLayoutImpl(gvEdge: self)
//}
//
//func asEdgeLayoutFixDirection(tailNode: CGPoint) throws -> EdgeLayout {
//    return try EdgeLayoutImpl(gvEdge: self).fixDirection(tailNode: tailNode)
//}

public struct EdgeLayout : Equatable, Hashable {
    /// the head is between arrowHead2 -> arrowHead
    public let arrowHead: CGPoint
    /// the tail is between arrowTail -> arrowTail2
    public let arrowTail: CGPoint
    /// the head is between arrowHead2 -> arrowHead
    public let arrowHead2: CGPoint
    /// the tail is between arrowTail -> arrowTail2
    public let arrowTail2: CGPoint
    public let path: CGPath
    public let labelPos: CGPoint?
    public let headLabelPos: CGPoint?
    public let tailLabelPos: CGPoint?
//
//    public let arrowHeadStype: GVEdgeEnding
//    public let arrowTailStype: GVEdgeEnding

    public init(gvEdge: GVEdge) throws {
        self.labelPos = gvEdge.labelPos
        self.headLabelPos = gvEdge.headLabelPos
        self.tailLabelPos = gvEdge.tailLabelPos

        guard let head = gvEdge.arrowHead, let tail = gvEdge.arrowTail else {
            throw LayoutError.gvHeadTailMissing
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
    
    public func getHeadPath(type: GVEdgeEnding) -> CGPath {
        return definePath(pos: arrowHead, type: type, otherPoint: arrowHead2)
    }
    
    public func getTailPath(type: GVEdgeEnding) -> CGPath {
        return definePath(pos: arrowTail, type: type, otherPoint: arrowTail2)
    }
    
    private func definePath (pos: CGPoint, type: GVEdgeEnding, otherPoint: CGPoint) -> CGPath {
        switch type {
            case .normal :
//                let secondPos = pos + CGVector(from: pos, to: otherPoint).normalized() * CGFloat(10.0)
//                return NSBezierPath(arrowHeadWithStartPoint: secondPos, endPoint: pos, tailWidth: 2, headWidth: 8, headLength: secondPos.distance(to: pos)).cgPath
                return NSBezierPath(arrowHeadWithStartPoint: otherPoint, endPoint: pos, tailWidth: 2, headWidth: 8, headLength: otherPoint.distance(to: pos)).cgPath
            case .dot:
//                let secondPos = pos + CGVector(from: pos, to: otherPoint).normalized() * CGFloat(8.0)
//                return NSBezierPath(circleBetween: pos, and: secondPos).cgPath
                return NSBezierPath(circleBetween: pos, and: otherPoint).cgPath
            case .none:
                let path = NSBezierPath()
                path.move(to: pos)
                path.line(to: otherPoint)
//                debugPrint("none - length \(CGVector(from: pos, to: otherPoint).length())")
                return path.cgPath
            case  .diamond:
//                let secondPos = pos + CGVector(from: pos, to: otherPoint) * CGFloat(10.0)
                return NSBezierPath(diamondBetween: pos, and: otherPoint).cgPath
        }
    }
    
}



// don't think I need this any longer
//extension EdgeLayout {
//    func fixDirection(tailNode: CGPoint) -> EdgeLayout {
//        let wrongDirection = tailNode.distance(to: arrowHead) < tailNode.distance(to: arrowTail)
//        if wrongDirection {
//            return EdgeLayoutImpl(path: path, labelPos: labelPos, headLabelPos: headLabelPos, tailLabelPos: tailLabelPos, arrowHead: arrowTail, arrowTail: arrowHead, arrowHead2: arrowTail2, arrowTail2: arrowHead2)
//        }
//        return self
//    }
//}
