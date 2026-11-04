//
//  ClusterAndUnflattenTests.swift
//  SwiftGraphvizTests
//
//  Cluster bounding boxes and labels, and the agUnflatten preprocessing pass.
//

import Testing
import GraphvizBridge
@testable import SwiftGraphviz

extension GraphvizTests {

    @Suite("Clusters")
    struct Clusters {

        static let dot = """
            digraph G {
                subgraph cluster_x { label="X"; a; b; }
                subgraph cluster_y { c; }
                a -> b; b -> c;
            }
            """

        @Test func clusterRectEnclosesItsNodes() throws {
            try withLayout(Self.dot) { g in
                let x = try subgraph(g, "cluster_x").rect
                let y = try subgraph(g, "cluster_y").rect
                let a = try node(g, "a").rect
                let b = try node(g, "b").rect
                let c = try node(g, "c").rect

                #expect(x.size.width > 0 && x.size.height > 0)
                #expect(x.contains(a, tolerance: 0) && x.contains(b, tolerance: 0))
                #expect(!x.intersects(c))
                #expect(y.contains(c, tolerance: 0))
                #expect(!y.intersects(a) && !y.intersects(b))

                // Clusters don't overlap and both sit inside the root bounding box.
                #expect(!x.intersects(y))
                let bb = boundingBox(g)
                #expect(bb.contains(x) && bb.contains(y))
            }
        }

        @Test func labelledClusterReportsLabel() throws {
            try withLayout(Self.dot) { g in
                let x = try subgraph(g, "cluster_x")
                #expect(x.labelText == "X")

                let lp = try #require(x.labelPos)
                #expect(x.rect.contains(lp))
                // Default labelloc for clusters is top: above the nodes inside it.
                let aTop = try node(g, "a").rect.maxY
                #expect(lp.y > aTop)

                let size = try #require(x.labelSize)
                #expect(size.width > 0 && size.height > 0)
            }
        }

        @Test func unlabelledClusterHasNoLabel() throws {
            try withLayout(Self.dot) { g in
                let y = try subgraph(g, "cluster_y")
                #expect(y.labelText == nil)
                #expect(y.labelPos == nil)
                #expect(y.labelSize == nil)
            }
        }

        @Test func clusterLayoutSnapshotMatchesCluster() throws {
            try withLayout(Self.dot) { g in
                let x = try subgraph(g, "cluster_x")
                let layout = ClusterLayout(cluster: x)
                #expect(layout.rect == x.rect)
                #expect(layout.labelPos == x.labelPos)
                #expect(layout.labelSize == x.labelSize)
                #expect(convertCluster(x) == layout)
            }
        }
    }

    @Suite("agUnflatten")
    struct Unflatten {

        static let fan = "digraph G { a -> {b c d e f}; }"

        @Test func withoutUnflattenFanIsOneRank() throws {
            try withLayout(Self.fan) { g in
                let ys = Set(try ["b", "c", "d", "e", "f"].map { try node(g, $0).pos.y })
                #expect(ys.count == 1)
            }
        }

        @Test func maxMinlenStaggersLeafEdges() throws {
            try withLayout(Self.fan, prepare: { $0.unflatten(maxMinlen: 3) }) { g in
                // Leaf edges get minlen 1, 2, 3, 1, 2 in creation order.
                let minlens = allEdges(g).map { attribute($0, "minlen") }
                #expect(minlens == ["1", "2", "3", "1", "2"])

                // ...which spreads the leaves over three ranks below a.
                let y = try ["a", "b", "c", "d", "e", "f"].reduce(into: [String: Double]()) {
                    $0[$1] = try node(g, $1).pos.y
                }
                let a = try #require(y["a"])
                #expect(isClose(a - y["b"]!, 72))
                #expect(isClose(a - y["c"]!, 144))
                #expect(isClose(a - y["d"]!, 216))
                #expect(isClose(y["e"]!, y["b"]!))
                #expect(isClose(y["f"]!, y["c"]!))
            }
        }

        @Test func zeroParametersChangeNothing() throws {
            try withLayout(Self.fan, prepare: { $0.unflatten() }) { g in
                #expect(allEdges(g).count == 5)
                #expect(allEdges(g).allSatisfy { (attribute($0, "minlen") ?? "").isEmpty })
                let ys = Set(try ["b", "c", "d", "e", "f"].map { try node(g, $0).pos.y })
                #expect(ys.count == 1)
            }
        }

        @Test func chainLimitChainsIsolatedNodes() throws {
            try withLayout("digraph G { x; y; z; }", prepare: { $0.unflatten(chainLimit: 3) }) { g in
                // Two invisible edges x -> y -> z are added.
                #expect(agnedges(g) == 2)
                #expect(attribute(try edge(g, "x", "y"), "style") == "invis")
                #expect(attribute(try edge(g, "y", "z"), "style") == "invis")

                let x = try node(g, "x").pos
                let y = try node(g, "y").pos
                let z = try node(g, "z").pos
                #expect(isClose(x.x, y.x) && isClose(y.x, z.x))
                #expect(x.y > y.y && y.y > z.y)
            }
        }
    }
}
