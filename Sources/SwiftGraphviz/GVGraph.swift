//
//  GVGraph.swift
//  SwiftGraphvizIOS
//
//  Created by Klaus Kneupner on 27/05/2019.
//  Copyright © 2019 Klaus Kneupner. All rights reserved.
//

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#elseif canImport(WASILibc)
import WASILibc
#endif
import GraphvizBridge


public typealias GVGraph = UnsafeMutablePointer<Agraph_t>

public extension UnsafeMutablePointer where Pointee == Agraph_t {

    // MARK: - Attribute helpers

    /// Register a default attribute value on this graph. Must be called before `set(_:_:)` on individual elements.
    ///
    /// Usage:
    /// ```swift
    /// g.setDefault(.node(.label))
    /// g.setDefault(.edge(.dir), value: "forward")
    /// g.setDefault(.graph(.rankdir), value: "LR")
    /// ```
    func setDefault(_ param: GVParameter, value: String = "") {
        let kind: Int32
        let name: String
        switch param {
        case .node(let p):  kind = Int32(AGNODE);  name = p.rawValue
        case .edge(let p):  kind = Int32(AGEDGE);  name = p.rawValue
        case .graph(let p): kind = Int32(AGRAPH);  name = p.rawValue
        }
        let cName = strdup(name)
        let cVal = strdup(value)
        agattr(self, kind, cName, cVal)
        free(cName)
        free(cVal)
    }

    /// Set a graph-level attribute value.
    func set(_ param: GVGraphParameters, _ value: String) {
        let cName = strdup(param.rawValue)
        let cVal = strdup(value)
        agset(self, cName, cVal)
        free(cName)
        free(cVal)
    }

    /// Get a graph-level attribute value.
    func get(_ param: GVGraphParameters) -> String {
        let cName = strdup(param.rawValue)
        defer { free(cName) }
        if let result = agget(self, cName) {
            return String(cString: result)
        }
        return ""
    }

    // MARK: - I/O

    func saveTo(fileName: String) {
        fileName.withCString { nameCStr in
            "w".withCString { modeCStr in
                guard let f = fopen(nameCStr, modeCStr) else { return }
                // agwrite takes `void *chan`; wrap because on WASI `FILE` is opaque
                // so fopen returns OpaquePointer, which has no implicit raw-pointer conversion.
                agwrite(self, UnsafeMutableRawPointer(f))
                fsync(fileno(f))
                fclose(f)
            }
        }
    }

    /// The graph serialized to DOT text.
    ///
    /// Uses `open_memstream` to give Graphviz's `agwrite` a `FILE*` backed by an
    /// auto-growing in-memory buffer. This avoids an OS pipe (which can deadlock
    /// once the output exceeds the pipe buffer, since nothing drains the read end)
    /// and keeps this Foundation-free so it builds for WebAssembly / embedded Swift.
    var asString: String? {
        var buffer: UnsafeMutablePointer<CChar>? = nil
        var size: Int = 0
        guard let stream = open_memstream(&buffer, &size) else {
            return nil
        }
        agwrite(self, UnsafeMutableRawPointer(stream))
        // Closing flushes the stream, then sets `buffer`/`size` and NUL-terminates.
        fclose(stream)
        guard let buffer else { return nil }
        defer { free(buffer) }
        return String(cString: buffer)
    }

    func unflatten(doFan: Bool = false, maxMinlen: Int32 = 0, chainLimit: Int32 = 0) {
        agUnflatten(self, doFan ? 1 : 0, maxMinlen, chainLimit)
    }
}
