//
//  GVLayoutConfig.swift
//  Vithanco
//
//  Created by Klaus Kneupner on 25/11/2018.
//  Copyright © 2018 Klaus Kneupner. All rights reserved.
//

import Foundation

public struct GVLayoutConfig {
    public let name: String
    public let layoutEngine: GVLayoutEngine
    public let renderEngine: GVLayoutEngine
    public var saveGVOutput: Bool
    public var params: GVParams
    public let secondLayoutEngine: GVLayoutEngine?
    public let supportClusters: Bool
    public var usesNodeDistance: Bool {
        return layoutEngine == .dot
    }
    
   public func layout(_ gvc: GVGlobalContextPointer, _ g: GVGraph) {
        gvLayout(gvc,g,layoutEngine.graphvizName)
        gvRender(gvc,g,renderEngine.graphvizName,nil)

        if let second = secondLayoutEngine {
//            gvLayout(gvc,g,second.graphvizName)
            gvRender(gvc,g,second.graphvizName,nil)
        }
    if saveGVOutput {
        Swift.print("now saving Graphviz Graph to file!")
        gvRenderFilename(gvc, g, "png", cString(("~/Downloads/Graphviz.png" as NSString).expandingTildeInPath))
//        gvRenderFilename(gvc, g, "cmap", cString("/Users/klauskneupner/Downloads/out.map"))
        
        //            gvRender(gvc, g, "plain", stdout);
    }
    }
    
    mutating public func config(graph: GraphSettings) {
        let  direction: GVModelDirection = graph.direction
        let edgeStyle = graph.edgeStyle
        let nodeSep: GVPixel = graph.minNodeDistanceX.asCGFloat
        let yDistance: GVPixel = graph.minNodeDistanceY.asCGFloat
        
        switch direction {
        case .towardsBottom, .towardsRight, .towardsLeft:
            params[.graph(.labelloc)] = "t"
        case .towardsTop:
            params[.graph(.labelloc)] = "b"
        }
        switch direction {
        case .towardsBottom,.towardsRight, .towardsTop:
            params[.graph(.labeljust)] = "l"
        case  .towardsLeft:
            params[.graph(.labeljust)] = "r"
        }
        
        params[.graph(.fontsize)] = "14"
        params[.graph(.ranksep)] = pixelToInchParameter(yDistance)
        params[.graph(.nodesep)] = pixelToInchParameter(nodeSep)
        params[.graph(.margin)] = pixelToInchParameter(12)
        params[.graph(.fontname)] = "Verdana-Bold"
        params[.graph(.label)] = ""
        params[.graph(.pad)] = "0.5"
        params[.graph(.sep)] = "0.05"
        params[.graph(.rankdir)] = direction.graphvizName
        params[.graph(.splines)] = edgeStyle.graphvizName
//        params[.graph(.newrank)] = "true"

        //        params[.graph(.rank)] = "max")
        params[.node(.style)] = "rounded"
        params[.node(.height)] = pixelToInchParameter(40)
        params[.node(.width)] = pixelToInchParameter(100)
        params[.node(.label)] = "correct me"
        params[.node(.fixedsize)] = "true"
        params[.node(.fontsize)] = "11"
        params[.node(.fontname)] = "Verdana"
        params[.node(.shape)] = "box"
        params[.node(.labelloc)] = "c"
        params[.node(.margin)] = "0"
        //        params[.graph,"color","white")
        //        params[.node(.ordering)] = "out")
        
        params[.edge(.constraint)] = "true"
        params[.edge(.label)] = ""
        params[.edge(.headport)] = "c"
        params[.edge(.tailport)] = "c"
        params[.edge(.samehead)] = ""
        params[.edge(.sametail)] = ""
        params[.edge(.headlabel)] = ""
        params[.edge(.labelangle)] = "45"
        params[.edge(.labeldistance)] = "2"
        params[.edge(.taillabel)] = ""
        params[.edge(.dir)] = "both"
        params[.edge(.weight)] = "1"
        params[.edge(.arrowtail)] = GVEdgeEnding.dot.graphvizName
        params[.edge(.arrowhead)] = GVEdgeEnding.normal.graphvizName
        params[.edge(.fontsize)] = "11"
        params[.edge(.fontname)] = "Verdana"
        //   params[.edge(.len", pixelToInchParameter((xDistance + yDistance) / 2.0))
    
    }
}
