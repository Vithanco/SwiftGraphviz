//
//  ClusterLayout.swift
//  SwiftGraphviz
//
//  Created by Klaus Kneupner on 02/09/2023.
//  Copyright © 2023 Klaus Kneupner. All rights reserved.
//

import Foundation
import CoreGraphics

public struct ClusterLayout: Equatable, Hashable {
    public let labelPos: CGPoint?
    public let labelSize: CGSize?
    public let rect: CGRect
    
    public static var zero: ClusterLayout {
        return ClusterLayout(labelPos: .zero, labelSize: .zero, rect: .zero)
    }
    
    public init(labelPos: CGPoint?, labelSize: CGSize?, rect: CGRect) {
        self.labelPos = labelPos
        self.labelSize = labelSize
        self.rect = rect
    }
}

public extension ClusterLayout {
    init (cluster: GVCluster) {
        self.init(labelPos: cluster.labelPos, labelSize: cluster.labelSize, rect: cluster.rect)
//        debugPrint("Created ClusterLayout: \(self)")
    }
}

public func convertCluster(_ gvCluster: GVCluster) -> ClusterLayout {
    return ClusterLayout(cluster: gvCluster)
}
