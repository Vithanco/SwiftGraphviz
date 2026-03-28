//
//  NodeLayout.swift
//  SwiftGraphviz
//
//  Created by Klaus Kneupner on 02/09/2023.
//  Copyright © 2023 Klaus Kneupner. All rights reserved.
//

public struct NodeLayout: Equatable, Sendable {

    public let pos: GVPoint
    public let size: GVSize

    public init(pos: GVPoint, size: GVSize) {
        self.pos = pos
        self.size = size
    }
    public init(node: GVNode) {
        self.pos = node.pos
        self.size = node.size
    }
    public static var zero: NodeLayout {
        return NodeLayout(pos: .zero, size: .zero)
    }
    public var rect: GVRect {
        return GVRect(midPoint: self.pos, size: self.size)
    }
}
