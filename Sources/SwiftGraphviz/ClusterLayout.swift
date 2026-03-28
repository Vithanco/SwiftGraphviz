//
//  ClusterLayout.swift
//  SwiftGraphviz
//
//  Created by Klaus Kneupner on 02/09/2023.
//  Copyright © 2023 Klaus Kneupner. All rights reserved.
//

public struct ClusterLayout: Equatable, Hashable, Sendable {
    public let labelPos: GVPoint?
    public let labelSize: GVSize?
    public let rect: GVRect

    public static var zero: ClusterLayout {
        return ClusterLayout(labelPos: .zero, labelSize: .zero, rect: .zero)
    }

    public init(labelPos: GVPoint?, labelSize: GVSize?, rect: GVRect) {
        self.labelPos = labelPos
        self.labelSize = labelSize
        self.rect = rect
    }
}

public extension ClusterLayout {
    init(cluster: GVCluster) {
        self.init(labelPos: cluster.labelPos, labelSize: cluster.labelSize, rect: cluster.rect)
    }
}

public func convertCluster(_ gvCluster: GVCluster) -> ClusterLayout {
    return ClusterLayout(cluster: gvCluster)
}
