//
//  GVGraphSerializationTests.swift
//  SwiftGraphvizTests
//
//  Exercises the Foundation-free `asString` (open_memstream) serialization path.
//

import Testing
import GraphvizBridge
@testable import SwiftGraphviz

@Suite("Graph serialization")
struct GVGraphSerializationTests {

    /// Round-trips a DOT string through Graphviz and back out via `asString`,
    /// exercising the `open_memstream`-based serialization that replaced the
    /// old Foundation `Pipe` implementation.
    @Test func asStringRoundTripsDot() throws {
        let dot = "digraph G { a -> b; a -> c; }"
        let graph = try #require(agmemread(dot), "agmemread should parse the DOT source")
        defer { agclose(graph) }

        let out = try #require(graph.asString, "asString should not be nil")
        #expect(out.contains("digraph"))
        #expect(out.contains("a -> b"))
        #expect(out.contains("a -> c"))
    }

    /// A large graph would deadlock the old pipe-based implementation once the
    /// output exceeded the OS pipe buffer (~64 KB). open_memstream has no such
    /// limit — this asserts we can serialize well past that boundary.
    @Test func asStringHandlesOutputLargerThanPipeBuffer() throws {
        var dot = "digraph Big {\n"
        for i in 0..<5000 {
            dot += "  n\(i) -> n\(i + 1);\n"
        }
        dot += "}\n"

        let graph = try #require(agmemread(dot))
        defer { agclose(graph) }

        let out = try #require(graph.asString)
        #expect(out.utf8.count > 64 * 1024, "output should exceed the old pipe-buffer limit")
        #expect(out.contains("n4999 -> n5000"))
    }
}
