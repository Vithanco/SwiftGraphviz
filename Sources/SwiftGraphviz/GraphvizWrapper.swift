//
//  GraphvizWrapper.swift
//  graphvizTest
//
//  Created by Klaus Kneupner on 3/2/17.
//  Copyright © 2017 Klaus Kneupner. All rights reserved.
//

import GraphvizBridge

enum GraphvizError: Error {
    case noPath
    case headTailMissing
}

/// Global Graphviz Context.
/// Initialized at module load with plugin registration. Must be freed with `finishGraphviz()` before app exit.
public nonisolated(unsafe) var gblGVContext: GVGlobalContextPointer = loadGraphvizLibraries()

public typealias GVSplines = UnsafeMutablePointer<splines>
public typealias GVBezier = UnsafeMutablePointer<bezier>

// On Apple, gvcint.h provides the full GVC_s struct definition so Swift can use
// UnsafeMutablePointer<GVC_t>. On Linux, GVC_t is opaque (forward-declared only),
// so Swift imports GVC_t* as OpaquePointer.
#if canImport(Darwin)
public typealias GVGlobalContextPointer = UnsafeMutablePointer<GVC_t>
#else
public typealias GVGlobalContextPointer = OpaquePointer
#endif

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
@MainActor public func finishGraphviz() {
    gvFreeContext(gblGVContext)
}
