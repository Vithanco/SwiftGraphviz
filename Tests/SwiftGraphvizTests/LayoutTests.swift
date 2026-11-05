//
//  LayoutTests.swift
//  SwiftGraphvizTests
//
//  Lays out small graphs with dot and neato and checks what the Swift layer
//  reads back: node positions and sizes, edge splines and arrow points,
//  edge labels, and the graph bounding box.
//
//  Coordinates are Graphviz points (72/inch) with the origin bottom-left, so in a
//  top-to-bottom dot layout a node on an earlier rank has a *larger* y.
//

import Testing
import GraphvizBridge
@testable import SwiftGraphviz

extension GraphvizTests {

    @Suite("dot layout")
    struct DotLayout {

        @Test func chainIsStackedTopToBottom() throws {
            try withLayout("digraph G { a -> b; b -> c; }") { g in
                let a = try node(g, "a").pos
                let b = try node(g, "b").pos
                let c = try node(g, "c").pos

                // Same column, decreasing y.
                #expect(isClose(a.x, b.x) && isClose(b.x, c.x))
                #expect(a.y > b.y && b.y > c.y)
                // Ranks are evenly spaced (default ranksep 0.5in + node height 0.5in = 72pt).
                #expect(isClose(a.y - b.y, 72))
                #expect(isClose(b.y - c.y, 72))
                // Values measured with the bundled Graphviz 16.1.0.
                #expect(isClose(a, GVPoint(x: 27, y: 162)))
                #expect(isClose(c, GVPoint(x: 27, y: 18)))
            }
        }

        @Test func rankdirLRLaysOutHorizontally() throws {
            try withLayout("digraph G { rankdir=LR; a -> b; }") { g in
                let a = try node(g, "a").pos
                let b = try node(g, "b").pos
                #expect(isClose(a.y, b.y))
                #expect(b.x > a.x)
            }
        }

        @Test func nodeSizeIsReportedInInchesAndPoints() throws {
            try withLayout("digraph G { a; big [width=2, height=1, fixedsize=true]; }") { g in
                let a = try node(g, "a")
                // Graphviz defaults: 0.75in x 0.5in.
                #expect(isClose(a.widthInches.value, 0.75, tolerance: 0.001))
                #expect(isClose(a.heightInches.value, 0.5, tolerance: 0.001))
                #expect(isClose(a.width.value, 54, tolerance: 0.01))
                #expect(isClose(a.height.value, 36, tolerance: 0.01))
                #expect(a.size == GVSize(width: a.width.value, height: a.height.value))

                let big = try node(g, "big")
                #expect(isClose(big.size.width, 144, tolerance: 0.01))
                #expect(isClose(big.size.height, 72, tolerance: 0.01))
            }
        }

        @Test func nodeLayoutSnapshotMatchesNode() throws {
            try withLayout("digraph G { a -> b; }") { g in
                let n = try node(g, "a")
                let layout = NodeLayout(node: n)
                #expect(layout.pos == n.pos)
                #expect(layout.size == n.size)
                #expect(layout.rect == n.rect)
                // rect is centred on pos.
                #expect(isClose(layout.rect.minX + layout.rect.size.width / 2, n.pos.x, tolerance: 0.001))
                #expect(isClose(layout.rect.minY + layout.rect.size.height / 2, n.pos.y, tolerance: 0.001))
            }
        }

        @Test func nodesDoNotOverlapAndFitInBoundingBox() throws {
            try withLayout("digraph G { a -> {b c d}; b -> e; c -> e; }") { g in
                let bb = boundingBox(g)
                let rects = try ["a", "b", "c", "d", "e"].map { try node(g, $0).rect }
                for r in rects {
                    #expect(bb.contains(r))
                }
                for i in rects.indices {
                    for j in rects.indices where j > i {
                        #expect(!rects[i].intersects(rects[j]))
                    }
                }
            }
        }

        @Test func edgeSplineRunsFromTailToHead() throws {
            try withLayout("digraph G { a -> b; }") { g in
                let a = try node(g, "a")
                let b = try node(g, "b")
                let e = try edge(g, "a", "b")

                let points = try e.getPath()
                // One cubic bezier: start point + 3 points per segment.
                #expect(points.count >= 4)
                #expect((points.count - 1) % 3 == 0)
                let allFinite = points.allSatisfy(\.isFinite)  // outside #expect: the macro treats the key path as throwing
                #expect(allFinite)

                // Spline starts at a's boundary and ends above b (before the arrowhead).
                #expect(isClose(points[0].x, a.pos.x))
                #expect(points[0].y < a.pos.y && points[0].y >= a.rect.minY - 1)
                let last = try #require(points.last)
                #expect(last.y > b.rect.maxY)

                // Directed edge: the arrowhead tip touches b's top boundary.
                let head = try #require(e.arrowHead)
                #expect(isClose(head.x, b.pos.x))
                #expect(isClose(head.y, b.rect.maxY, tolerance: 1))
                #expect(head.y < last.y)
            }
        }

        @Test func edgeLayoutSnapshotMatchesEdge() throws {
            try withLayout("digraph G { a -> b; }") { g in
                let e = try edge(g, "a", "b")
                let layout = try EdgeLayout(gvEdge: e)
                let points = try e.getPath()
                #expect(layout.controlPoints == points)
                #expect(layout.arrowTail2 == points[0])
                #expect(layout.arrowHead2 == points[points.count - 1])
                #expect(layout.arrowHead == e.arrowHead)
                #expect(layout.labelPos == nil)
            }
        }

        @Test func edgeLabelIsPlacedBetweenNodes() throws {
            try withLayout(#"digraph G { a -> b [label="hello"]; }"#) { g in
                let a = try node(g, "a").pos
                let b = try node(g, "b").pos
                let e = try edge(g, "a", "b")

                #expect(e.labelText == "hello")
                let lp = try #require(e.labelPos)
                #expect(lp.y < a.y && lp.y > b.y)
                // dot puts the label beside the edge, not on top of it.
                #expect(lp.x > a.x)

                #expect(try EdgeLayout(gvEdge: e).labelPos == lp)
                #expect(e.headLabelPos == nil)
                #expect(e.tailLabelPos == nil)
            }
        }

        @Test func boundingBoxStartsAtOriginAndContainsEverything() throws {
            try withLayout("digraph G { a -> b; b -> c; }") { g in
                let bb = boundingBox(g)
                #expect(bb.origin == .zero)
                #expect(isClose(bb.size.width, 54))
                #expect(isClose(bb.size.height, 180))
                for e in allEdges(g) {
                    for p in try e.getPath() {
                        #expect(bb.contains(p))
                    }
                }
            }
        }

        @Test func attributesSetFromSwiftAffectLayout() throws {
            try withLayout(
                "digraph G { a -> b; }",
                prepare: { g in
                    g.setDefault(.graph(.rankdir), value: "TB")
                    g.set(.rankdir, "LR")
                }
            ) { g in
                #expect(g.get(.rankdir) == "LR")
                let a = try node(g, "a").pos
                let b = try node(g, "b").pos
                #expect(isClose(a.y, b.y))
                #expect(b.x > a.x)
            }
        }
    }

    @Suite("neato layout")
    struct NeatoLayout {

        static let triangle = "graph G { a -- b; b -- c; c -- a; }"

        @Test func trianglePlacesNodesApart() throws {
            try withLayout(Self.triangle, engine: .neato) { g in
                let points = try ["a", "b", "c"].map { try node(g, $0).pos }
                let allFinite = points.allSatisfy(\.isFinite)  // outside #expect: the macro treats the key path as throwing
                #expect(allFinite)

                // Equal edge weights: the three sides have roughly the same length.
                let d = [points[0].distance(to: points[1]),
                         points[1].distance(to: points[2]),
                         points[2].distance(to: points[0])]
                let minD = try #require(d.min())
                let maxD = try #require(d.max())
                #expect(minD > 54, "nodes should not overlap")
                #expect(maxD / minD < 1.2)

                // Not collinear: c is clearly off the line a-b.
                let ab = GVVector(dx: points[1].x - points[0].x, dy: points[1].y - points[0].y)
                let ac = GVVector(dx: points[2].x - points[0].x, dy: points[2].y - points[0].y)
                let cross = ab.dx * ac.dy - ab.dy * ac.dx
                #expect(abs(cross) > 1000)
            }
        }

        @Test func layoutIsDeterministic() throws {
            let first = try withLayout(Self.triangle, engine: .neato) { g in
                try ["a", "b", "c"].map { try node(g, $0).pos }
            }
            let second = try withLayout(Self.triangle, engine: .neato) { g in
                try ["a", "b", "c"].map { try node(g, $0).pos }
            }
            #expect(first == second)
        }

        @Test func edgesConnectTheirEndpointsAndFitInBoundingBox() throws {
            try withLayout(Self.triangle, engine: .neato) { g in
                let bb = boundingBox(g)
                let edges = allEdgesWithEnds(g)
                #expect(edges.count == 3)
                for (tail, head, e) in edges {
                    let points = try e.getPath()
                    #expect(points.count >= 4)
                    let first = points[0]
                    let last = points[points.count - 1]
                    // Each spline starts near its tail node and ends near its head node
                    // (on the boundary, so within about half a node diagonal).
                    #expect(first.distance(to: tail.pos) < 40)
                    #expect(last.distance(to: head.pos) < 40)
                    #expect(first.distance(to: head.pos) > last.distance(to: head.pos))
                    for p in points {
                        #expect(bb.contains(p))
                    }
                }
                for name in ["a", "b", "c"] {
                    #expect(bb.contains(try node(g, name).rect))
                }
            }
        }
    }
}
