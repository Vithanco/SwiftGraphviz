//
//  ClusterLayout.swift
//  SwiftGraphviz
//
//  Created by Klaus Kneupner on 02/09/2023.
//  Copyright © 2023 Klaus Kneupner. All rights reserved.
//

import Foundation
import CoreGraphics

extension CGRect: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.origin)
        hasher.combine(self.size)
    }
}

extension CGSize : Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.width)
        hasher.combine(self.height)
    }
}

public struct ClusterLayout : Equatable, Hashable{
    public let labelPos: CGPoint?
    public let labelSize: CGSize?
    public let rect: CGRect
    
    public static var zero: ClusterLayout {
        return ClusterLayout(labelPos: .zero, labelSize: .zero, rect: .zero)
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
