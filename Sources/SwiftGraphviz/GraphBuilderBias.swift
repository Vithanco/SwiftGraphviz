//
//  GraphBuilderBias.swift
//  Vithanco
//
//  Created by Klaus Kneupner on 17/05/2019.
//  Copyright © 2019 Klaus Kneupner. All rights reserved.
//

import Foundation



/// Similar to Bias from Flying Logic. Not perfect but good enough.
public struct GraphBuilderBias: GraphBuilder {
    let base: GraphBuilder
    let newDir: GVModelDirection

    public var graph: GVGraph {
        return base.graph
    }

    public init(base: GraphBuilder, originalDirection: GVModelDirection) {
        self.base = base
        self.newDir = originalDirection.opposite

//        base.setBaseValue(param: .edge(.dir), value: GVEdgeParamDir.back.rawValue)
    }

    public func newNode(name: String, label: String, cluster: GVCluster?) -> GVNode {
        return base.newNode(name: name, label: label, cluster: cluster)
    }

    public func newEdge(from: GVNode, to: GVNode, name: String, dir: GVEdgeParamDir) -> GVEdge? {
        assert(dir == .both)
        return base.newEdge(from: to, to: from, name: name, dir: dir)
    }

    public func newCluster(name: String, label: String, parent: GVCluster?) -> GVCluster {
        let result = base.newCluster(name: name, label: label, parent: parent )
        return result
    }

    public func setNodeSize(node: GVNode, width: GVPixel, height: GVPixel) {
        return base.setNodeSize(node: node, width: width, height: height)
    }

    public func setFontSize(node: GVNode, fontSize: CGFloat) {
        base.setFontSize(node: node, fontSize: fontSize)
    }

    public func setNodeShape(node: GVNode, shape: GVNodeShape) {
        base.setNodeShape(node: node, shape: shape)
    }

    public func setBaseValue(param: GVParameter, value: String) {
        if case .graph(let gp) = param {
            if newDir.isHorizontal {
                if gp == .labeljust {
                    if value == "r" {
                        base.setBaseValue(param: param, value: "l")
                        return
                    }
                    if value == "l" {
                        base.setBaseValue(param: param, value: "r")
                        return
                    }
                }
            } else { //vertical
                if gp == .labelloc {
                    if value == "b" {
                        base.setBaseValue(param: param, value: "t")
                        return
                    }
                    if value == "t" {
                        base.setBaseValue(param: param, value: "b")
                        return
                    }
                }
            }
             if gp == .rankdir {
                let rankDir = GVModelDirection.fromGraphvizName(value: value).opposite
                base.setBaseValue(param: .graph(.rankdir), value: rankDir.graphvizName)
                return
            }
        }
        if case .edge(let ep) = param {
            if ep == .arrowhead {
                base.setBaseValue(param: .edge(.arrowtail), value: value)
                return
            }
            if ep == .arrowtail {
                base.setBaseValue(param: .edge(.arrowhead), value: value)
                return
            }
            if ep == .headlabel {
                base.setBaseValue(param: .edge(.taillabel), value: value)
                return
            }
            if ep == .taillabel {
                base.setBaseValue(param: .edge(.headlabel), value: value)
                return
            }
        }
        base.setBaseValue(param: param, value: value)
    }

    public func setNodeValue(_ node: GVNode, _ param: GVNodeParameters, _ value: String) {
        base.setNodeValue(node, param, value)
    }

    public func setEdgeValue(_ edge: GVEdge, _ param: GVEdgeParameters, _ value: String) {
        if param == .arrowhead {
            base.setEdgeValue(edge, .arrowtail, value)
            return
        }
        if param == .arrowtail {
            base.setEdgeValue(edge, .arrowhead, value)
            return
        }
        base.setEdgeValue(edge, param, value)
    }

    public func setGraphValue(_ param: GVGraphParameters, _ value: String) {
        base.setGraphValue(param, value)
    }
    
    public func getGraphValue(_ param: GVGraphParameters) -> String {
        return base.getGraphValue(param)
    }

    public func setClusterValue(_ cluster: GVCluster, _ param: GVGraphParameters, _ value: String) {
        base.setClusterValue(cluster, param, value)
    }

    public func layout() {
        base.layout()
    }

    public func getGraphRect() -> CGRect {
        return base.getGraphRect()
    }

}
