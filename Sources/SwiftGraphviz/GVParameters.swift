//
//  GVParameters.swift
//  Vithanco
//
//  Created by Klaus Kneupner on 19/01/2019.
//  Copyright © 2019 Klaus Kneupner. All rights reserved.
//

import Foundation
import CoreGraphics


let pointsPerInch: CGFloat = 72.0

func pixelToInchParameter(_ x: CGFloat) -> String {
    return "\(x / pointsPerInch)"
}



public enum GVEdgeParameters : String {
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
    case taillabel
    case labelangle
    case labeldistance
    case len
    case fontname
    case fontsize
}

public enum GVGraphParameters : String {
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
}

public enum GVNodeParameters : String {
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

public enum GVParameter : Hashable {
    case graph(GVGraphParameters)
    case edge(GVEdgeParameters)
    case node(GVNodeParameters)
}

public enum GVEdgeParamDir : String {
    case both
    case forward
    case back
    case none
    
    static func showing(head: Bool, tail: Bool) -> GVEdgeParamDir {
        if head {
            if tail {
                return .both
            } else {
                return .forward
            }
        } else {
            if tail {
                return .back
            } else {
                return .none
            }
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

public enum GVParamValueOverlap : String {
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

@objc public enum GVEdgeEnding: Int {
    
    /// no ending
    case none = 0
    
    ///arrow
    case normal
    
    ///small circle
    case dot
    
    ///diamond
    case diamond
    
    
    static var readableNames: [String] {
        return ["None", "Arrow", "Dot", "Diamond"]
    }
    
    public var graphvizName : String {
        switch self {
        case .none:  return "none"
        case .normal:  return  "normal"
        case .dot:  return  "dot"
        case .diamond:  return  "diamond"
        }
    }
}

@objc public enum GVEdgeStyle: Int {
    case curved = 0
    case lines
    case polyLines
    case orthogonal
    case splines
    
    var graphvizName: String {
        switch self {
        case .curved:
            return "curved"
        case .lines:
            return "line"
        case .polyLines:
            return "polyLine"
        case .orthogonal:
            return "ortho"
        case .splines:
            return "spline"
        }
    }
    
    public static var readableNames: [String] {
        return ["Curved", "Lines", "PolyLines", "Orthogonal", "Splines"]
    }
}


@objc public enum GVRank: Int {
    case same
    case min
    case source
    case max
    case sink
    
    var graphvizName: String {
        switch self {
        case .same:
            return "same"
        case .min:
            return "min"
        case .source:
            return "source"
        case .max:
            return "max"
        case .sink:
            return "sink"
        }
    }
    
    static var readableNames: [String] {
        return ["Same", "Min", "Source", "Max","Sink"]
    }
}

