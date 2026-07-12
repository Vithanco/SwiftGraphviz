//
//  GraphvizWrapper.swift
//  graphvizTest
//
//  Created by Klaus Kneupner on 3/2/17.
//  Copyright © 2017 Klaus Kneupner. All rights reserved.
//

import GraphvizBridge

/// Errors from reading layout results off Graphviz structures.
///
/// Public and used with typed `throws` so the throwing API compiles under
/// Embedded Swift, which forbids `any Error` existentials.
public enum GraphvizError: Error {
    case noPath
    case headTailMissing
}

/// Global Graphviz Context.
/// Initialized at module load with plugin registration. Must be freed with `finishGraphviz()` before app exit.
public nonisolated(unsafe) var gblGVContext: GVGlobalContextPointer = loadGraphvizLibraries()

public typealias GVSplines = UnsafeMutablePointer<splines>
public typealias GVBezier = UnsafeMutablePointer<bezier>

// gvcint.h is available on all platforms (xcframework on Apple, artifact bundle
// on Linux), so GVC_t is always a full struct and never opaque.
public typealias GVGlobalContextPointer = UnsafeMutablePointer<GVC_t>

public enum GVLayoutEngine: Int, CaseIterable {
    case dot = 0
    case neato
    case fdp
    case nop
    case nop2
    case twopi

    public var graphvizName: String {
        switch self {
        case .dot: return "dot"
        case .neato: return "neato"
        case .fdp: return "fdp"
        case .nop: return "nop"
        case .nop2: return "nop2"
        case .twopi: return "twopi"
        }
    }

    public var supportsLayers: Bool {
        return self != .neato
    }
}

/// Needs to be called once before closing down the application
#if os(WASI)
// Embedded Swift (wasm) has no global actors and is single-threaded, so @MainActor
// is both unavailable and unnecessary here.
public func finishGraphviz() {
    gvFreeContext(gblGVContext)
}
#else
@MainActor public func finishGraphviz() {
    gvFreeContext(gblGVContext)
}
#endif
