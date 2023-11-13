//
//  NodeLayout.swift
//  SwiftGraphviz
//
//  Created by Klaus Kneupner on 02/09/2023.
//  Copyright © 2023 Klaus Kneupner. All rights reserved.
//

import Foundation

public  struct NodeLayout: Equatable {
    public let pos: CGPoint
    public let size: CGSize
    public init(pos: CGPoint,size: CGSize) {
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
    public var rect: CGRect {
        return CGRect(midPoint: self.pos, size: self.size)
    }
}
