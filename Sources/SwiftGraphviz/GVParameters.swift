//
//  GVParameters.swift
//  Vithanco
//
//  Created by Klaus Kneupner on 19/01/2019.
//  Copyright © 2019 Klaus Kneupner. All rights reserved.
//

// MARK: - Unit Types

/// Graphviz uses 72 points per inch
public let pointsPerInch: Double = 72.0

/// A value measured in screen points (72 points = 1 inch).
/// Use this for sizes as seen on screen / in CoreGraphics coordinates.
public struct GVPoints: Equatable, Hashable, Sendable {
    public let value: Double
    public init(_ value: Double) { self.value = value }
    public var asInches: GVInches { GVInches(value / pointsPerInch) }
}

/// A value measured in inches, as used internally by Graphviz for node width/height.
public struct GVInches: Equatable, Hashable, Sendable {
    public let value: Double
    public init(_ value: Double) { self.value = value }
    public var asPoints: GVPoints { GVPoints(value * pointsPerInch) }
}

/// Convert a point value to the inch-based string parameter that Graphviz expects.
public func pixelToInchParameter(_ x: GVPoints) -> String {
    return "\(x.asInches.value)"
}

// MARK: - Parameter Enums

public enum GVEdgeParameters: String, CaseIterable {
    case arrowtail
    case arrowhead
    case dir
    case weight
    case constraint
    case label
    case xlabel
    case samehead
    case headport
    case sametail
    case tailport
    case style
    case headlabel
    case headtooltip
    case taillabel
    case labelangle
    case labeldistance
    case labelfloat
    case labelfontsize
    case len
    case fontname
    case fontsize
}

public enum GVGraphParameters: String, CaseIterable {
    case overlap
    case sep
    case margin  // warning: for graph in Inches, for cluster in points
    case ranksep
    case nodesep
    case rankdir
    case splines
    case fontname
    case label
    case pad
    case labelloc
    case labeljust
    case fontsize
    case epsilon
    case rank
    case newrank
}

public enum GVNodeParameters: String, CaseIterable {
    case width
    case height
    case shape
    case style
    case label
    case fixedsize
    case fontsize
    case fontname
    case labelloc
    case margin
}

public enum GVParameter: Hashable {
    case graph(GVGraphParameters)
    case edge(GVEdgeParameters)
    case node(GVNodeParameters)
}

public typealias GVParams = [GVParameter: String]

// MARK: - Edge Direction

public enum GVEdgeParamDir: String, CaseIterable {
    case both
    case forward
    case back
    case none

    static func showing(head: Bool, tail: Bool) -> GVEdgeParamDir {
        if head {
            return tail ? .both : .forward
        } else {
            return tail ? .back : .none
        }
    }

    public var opposite: GVEdgeParamDir {
        switch self {
        case .both, .none:
            return self
        case .back:
            return .forward
        case .forward:
            return .back
        }
    }
}

// MARK: - Overlap

public enum GVParamValueOverlap: String, CaseIterable {
    case retain = "true"
    case scale
    case prism1000
    case prism0
    case voronoi
    case scalexy
    case compress
    case vpsc
    case ipsep // requires neato and mode=ipsep
    case fdpDefault = "9:prism"
}

// MARK: - Edge Ending (used by EdgeLayout rendering)

public enum GVEdgeEnding: Int, CaseIterable {
    /// no ending
    case none = 0
    /// arrow
    case normal
    /// small circle
    case dot
    /// diamond
    case diamond

    public var graphvizName: String {
        switch self {
        case .none:  return "none"
        case .normal:  return "normal"
        case .dot:  return "dot"
        case .diamond:  return "diamond"
        }
    }
}

// MARK: - Edge Style

public enum GVEdgeStyle: Int, CaseIterable {
    case curved = 0
    case lines
    case polyLines
    case orthogonal
    case splines

    public var graphvizName: String {
        switch self {
        case .curved: return "curved"
        case .lines: return "line"
        case .polyLines: return "polyLine"
        case .orthogonal: return "ortho"
        case .splines: return "spline"
        }
    }
}

// MARK: - Rank

public enum GVRank: Int, CaseIterable {
    case same
    case min
    case source
    case max
    case sink

    public var graphvizName: String {
        switch self {
        case .same: return "same"
        case .min: return "min"
        case .source: return "source"
        case .max: return "max"
        case .sink: return "sink"
        }
    }
}
