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

public func pixelToInchParameter(_ x: CGFloat) -> String {
    return "\(x / pointsPerInch)"
}



public enum GVEdgeParameters : String, CaseIterable {
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
    
    static var readableNames: [String] {
        return allCases.map({$0.rawValue})
    }
    
    public var readableName : String {
        return self.rawValue
    }
}

public enum GVGraphParameters : String , CaseIterable{
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
    
    static var readableNames: [String] {
        return allCases.map({$0.rawValue})
    }
    
    public var readableName : String {
        return self.rawValue
    }
}

public enum GVNodeParameters : String, CaseIterable {
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
    
    static var readableNames: [String] {
        return allCases.map({$0.rawValue})
    }
    
    public var readableName : String {
        return self.rawValue
    }
}

public enum GVParameter : Hashable {
    case graph(GVGraphParameters)
    case edge(GVEdgeParameters)
    case node(GVNodeParameters)
}

public enum GVEdgeParamDir : String , CaseIterable {
    case both
    case forward
    case back
    case none
    
    static var readableNames: [String] {
        return allCases.map({$0.readableName})
    }
    
    public var readableName : String {
        switch self {
            case .both: return "Both Directions"
            case .forward: return "Forward Only"
            case .back: return "Backward Only"
            case .none: return "None"
        }
    }
    
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

public enum GVParamValueOverlap : String , CaseIterable{
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
    
    
    static var readableNames: [String] {
        return allCases.map({$0.readableName})
    }
    
    public var readableName : String {
        switch self {
            case .retain:   return "Retain"
            case .scale: return "scale"
            case .prism1000: return "prism1000"
            case .prism0: return "prism0"
            case .voronoi: return "voronoi"
            case .scalexy: return "scalexy"
            case .compress: return "compress"
            case .vpsc: return "vpsc"
            case .ipsep: return "ipsep"
            case .fdpDefault: return "fdpDefault"
        }
    }
    
}

@objc public enum GVEdgeEnding: Int , Codable, CaseIterable{
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
    
    public var readableName : String {
        return GVEdgeEnding.readableNames[self.rawValue]
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

@objc public enum GVEdgeStyle: Int, CaseIterable {
    case curved = 0
    case lines
    case polyLines
    case orthogonal
    case splines
    
    public var graphvizName: String {
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
    
    public var readableName : String {
        return GVEdgeStyle.readableNames[self.rawValue]
    }
}


@objc public enum GVRank: Int, CaseIterable {
    case same
    case min
    case source
    case max
    case sink
    
    public var graphvizName: String {
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
    
    public var readableName : String {
        return GVRank.readableNames[self.rawValue]
    }
}

