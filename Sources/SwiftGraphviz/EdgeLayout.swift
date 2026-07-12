//
//  EdgeLayout.swift
//  SwiftGraphviz
//
//  Created by Klaus Kneupner on 02/09/2023.
//  Copyright © 2023 Klaus Kneupner. All rights reserved.
//


public struct EdgeLayout: Equatable, Hashable, Sendable {
    /// the head is between arrowHead2 -> arrowHead
    public let arrowHead: GVPoint
    /// the tail is between arrowTail -> arrowTail2
    public let arrowTail: GVPoint
    /// the head is between arrowHead2 -> arrowHead
    public let arrowHead2: GVPoint
    /// the tail is between arrowTail -> arrowTail2
    public let arrowTail2: GVPoint
    /// Raw cubic bezier control points. Build a path from these:
    /// move(to: [0]), then for each stride of 3: curve(to: [i+2], control1: [i], control2: [i+1])
    public let controlPoints: [GVPoint]
    public let labelPos: GVPoint?
    public let headLabelPos: GVPoint?
    public let tailLabelPos: GVPoint?

    public init(gvEdge: GVEdge) throws(GraphvizError) {
        self.labelPos = gvEdge.labelPos
        self.headLabelPos = gvEdge.headLabelPos
        self.tailLabelPos = gvEdge.tailLabelPos

        guard let head = gvEdge.arrowHead, let tail = gvEdge.arrowTail else {
            throw GraphvizError.headTailMissing
        }
        arrowHead = head
        arrowTail = tail

        let points = try gvEdge.getPath()
        controlPoints = points
        arrowHead2 = points[points.count - 1]
        arrowTail2 = points[0]
    }
}
