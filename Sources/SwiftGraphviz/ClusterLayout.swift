//
//  ClusterLayout.swift
//  SwiftGraphviz
//
//  Created by Klaus Kneupner on 02/09/2023.
//  Copyright © 2023 Klaus Kneupner. All rights reserved.
//

import Foundation



// MARK: Cluster
public protocol ClusterLayout {
    var labelPos: CGPoint? {get}
    var labelSize: CGSize? {get}
    var rect: CGRect {get}
}

public struct ClusterLayoutImpl: ClusterLayout {
    public let labelPos: CGPoint?
    public let labelSize: CGSize?
    public let rect: CGRect
}

extension ClusterLayoutImpl {
    init (cluster: GVCluster) {
        self.init(labelPos: cluster.labelPos, labelSize: cluster.labelSize, rect: cluster.rect)
    }
}

extension GVCluster : ClusterLayout {
    
}

func convertCluster(_ gvCluster: GVCluster) -> ClusterLayout {
    return ClusterLayoutImpl(cluster: gvCluster)
}
