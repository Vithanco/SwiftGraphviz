//
//  NodeLayout.swift
//  SwiftGraphviz
//
//  Created by Klaus Kneupner on 02/09/2023.
//  Copyright © 2023 Klaus Kneupner. All rights reserved.
//

import Foundation


// MARK: Node
public protocol NodeLayout {
    var pos: CGPoint {get}
    var size: CGSize {get}
}

private struct NodeLayoutImpl: NodeLayout {
    let pos: CGPoint
    let size: CGSize
    init(node: GVNode) {
        self.pos = node.pos
        self.size = node.size
    }
}

private extension NodeLayoutImpl {
    var rect: CGRect {
        return CGRect(midPoint: self.pos, size: self.size)
    }
}

 extension GVNode: NodeLayout {
    
}

func convertNodeLayout(_ gvNode: GVNode) -> NodeLayout {
    return NodeLayoutImpl(node: gvNode)
}
