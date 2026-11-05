//
//  GraphvizTests.swift
//  SwiftGraphvizTests
//
//  Root suite and shared helpers for tests that drive the Graphviz C library.
//

import Testing
import GraphvizBridge
@testable import SwiftGraphviz

/// Root suite for everything that touches Graphviz.
///
/// Graphviz is not thread-safe (the DOT parser, the shared `gblGVContext` and
/// `agUnflatten`'s module-level state are all global), while Swift Testing runs
/// tests in parallel by default. `.serialized` here applies to every nested suite.
@Suite(.serialized)
struct GraphvizTests {}

// MARK: - Helpers

/// Parses `dot`, optionally preprocesses it, runs `engine`, and hands the laid-out
/// graph to `body`. Layout and graph are always freed afterwards.
func withLayout<R>(
    _ dot: String,
    engine: GVLayoutEngine = .dot,
    prepare: (GVGraph) -> Void = { _ in },
    _ body: (GVGraph) throws -> R
) throws -> R {
    let graph = try #require(agmemread(dot), "agmemread should parse the DOT source")
    defer { agclose(graph) }
    prepare(graph)
    let rc = gvLayout(gblGVContext, graph, engine.graphvizName)
    try #require(rc == 0, "gvLayout(\(engine.graphvizName)) failed")
    defer { gvFreeLayout(gblGVContext, graph) }
    return try body(graph)
}

/// Looks up an existing node by name.
func node(_ graph: GVGraph, _ name: String) throws -> GVNode {
    let n = name.withCString { agnode(graph, UnsafeMutablePointer(mutating: $0), 0) }
    return try #require(n, "node \(name) not found")
}

/// Looks up an existing subgraph (e.g. a cluster) by name.
func subgraph(_ graph: GVGraph, _ name: String) throws -> GVCluster {
    let sg = name.withCString { agsubg(graph, UnsafeMutablePointer(mutating: $0), 0) }
    return try #require(sg, "subgraph \(name) not found")
}

/// Looks up an existing edge tail -> head.
func edge(_ graph: GVGraph, _ tail: String, _ head: String) throws -> GVEdge {
    let t = try node(graph, tail)
    let h = try node(graph, head)
    let e = agedge(graph, t, h, nil, 0)
    return try #require(e, "edge \(tail) -> \(head) not found")
}

/// All edges with their endpoints, in Graphviz iteration order (by tail node,
/// then edge creation order). `agtail`/`aghead` are C macros Swift can't import;
/// for an out-edge the head is `edge.pointee.node`.
func allEdgesWithEnds(_ graph: GVGraph) -> [(tail: GVNode, head: GVNode, edge: GVEdge)] {
    var result: [(tail: GVNode, head: GVNode, edge: GVEdge)] = []
    var n = agfstnode(graph)
    while let current = n {
        var e = agfstout(graph, current)
        while let ce = e {
            result.append((tail: current, head: ce.pointee.node, edge: ce))
            e = agnxtout(graph, ce)
        }
        n = agnxtnode(graph, current)
    }
    return result
}

/// All edges, in Graphviz iteration order.
func allEdges(_ graph: GVGraph) -> [GVEdge] {
    allEdgesWithEnds(graph).map(\.edge)
}

/// Reads a string attribute from any Graphviz object (graph, node, edge).
func attribute<T>(_ object: UnsafeMutablePointer<T>, _ name: String) -> String? {
    let value = name.withCString { agget(UnsafeMutableRawPointer(object), UnsafeMutablePointer(mutating: $0)) }
    return value.map { String(cString: $0) }
}

/// The graph's bounding box (root graph or cluster).
func boundingBox(_ graph: GVGraph) -> GVRect {
    GVRect(box: gd_bb(graph))
}

extension GVRect {
    var minX: Double { origin.x }
    var minY: Double { origin.y }
    var maxX: Double { origin.x + size.width }
    var maxY: Double { origin.y + size.height }

    func contains(_ p: GVPoint, tolerance: Double = 0.5) -> Bool {
        p.x >= minX - tolerance && p.x <= maxX + tolerance &&
        p.y >= minY - tolerance && p.y <= maxY + tolerance
    }

    func contains(_ r: GVRect, tolerance: Double = 0.5) -> Bool {
        contains(r.origin, tolerance: tolerance) &&
        contains(GVPoint(x: r.maxX, y: r.maxY), tolerance: tolerance)
    }

    func intersects(_ r: GVRect) -> Bool {
        minX < r.maxX && r.minX < maxX && minY < r.maxY && r.minY < maxY
    }
}

func isClose(_ a: Double, _ b: Double, tolerance: Double = 0.5) -> Bool {
    abs(a - b) <= tolerance
}

func isClose(_ a: GVPoint, _ b: GVPoint, tolerance: Double = 0.5) -> Bool {
    isClose(a.x, b.x, tolerance: tolerance) && isClose(a.y, b.y, tolerance: tolerance)
}
