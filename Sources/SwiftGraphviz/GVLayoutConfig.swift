//
//  GVLayoutConfig.swift
//  Vithanco
//
//  Created by Klaus Kneupner on 25/11/2018.
//  Copyright © 2018 Klaus Kneupner. All rights reserved.
//

import Foundation
//import Vithanco

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
        g.saveTo(fileName: "simplegraph.dot")
        
        gvLayout(gvc,g,layoutEngine.graphvizName)
    //    gvRender(gvc,g,renderEngine.graphvizName,nil)
        
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
    
}
