//
//  EdgeLayout.swift
//  SwiftGraphviz
//
//  Created by Klaus Kneupner on 02/09/2023.
//  Copyright © 2023 Klaus Kneupner. All rights reserved.
//

import Foundation
import CoreGraphics


// MARK: Edge
public protocol EdgeLayout {
    var path: CGPath {get}
    var labelPos: CGPoint? {get}
    var headLabelPos: CGPoint? {get}
    var tailLabelPos: CGPoint? {get}

    /// the head is between arrowHead2 -> arrowHead
    var arrowHead: CGPoint {get}
    /// the head is between arrowHead2 -> arrowHead
    var arrowHead2: CGPoint {get}

    /// the tail is between arrowTail -> arrowTail2
    var arrowTail: CGPoint {get}
    /// the tail is between arrowTail -> arrowTail2
    var arrowTail2: CGPoint {get}

  //  func fixDirection(tailNode: CGPoint) -> EdgeLayout
}






//func asEdgeLayout() throws -> EdgeLayout {
//    return try EdgeLayoutImpl(gvEdge: self)
//}
//
//func asEdgeLayoutFixDirection(tailNode: CGPoint) throws -> EdgeLayout {
//    return try EdgeLayoutImpl(gvEdge: self).fixDirection(tailNode: tailNode)
//}

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
}

func convertEdge(_ gvEdge: GVEdge) throws -> EdgeLayout{
    return try EdgeLayoutImpl(gvEdge: gvEdge)
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
