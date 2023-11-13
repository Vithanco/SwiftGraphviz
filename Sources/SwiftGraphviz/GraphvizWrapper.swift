//
//  GraphvizWrapper.swift
//  graphvizTest
//
//  Created by Klaus Kneupner on 3/2/17.
//  Copyright © 2017 Klaus Kneupner. All rights reserved.
//

import Foundation

enum GraphvizError : Error {
    case noPath
    case headTailMissing
}

///Global Graphviz Context.
///To be set at program start and freed and progam end
fileprivate var gblGVContext: GVGlobalContextPointer = loadGraphvizLibraries() //UnsafeMutablePointer<GVC_t>?

public typealias CHAR = UnsafeMutablePointer<Int8>
public typealias CHAR_ARRAY = UnsafeMutablePointer<UnsafeMutablePointer<Int8>>
public typealias GVSplines = UnsafeMutablePointer<splines>
public typealias GVBezier = UnsafeMutablePointer<bezier>
public typealias GVPixel = CGFloat
public typealias GVGlobalContextPointer = UnsafeMutablePointer<GVC_t>

public let stdFontName = "Verdana"
public let stdFontNameBold = "Verdana-Bold"

@objc public enum GVLayoutEngine: Int , CaseIterable{
    case dot = 0
    case neato
    case fdp
    case nop
    case nop2
    case twopi
    
    public static var readableNames: [String] {
        return ["Layered (dot)", "Star (neato)", "Star (fdp)", "Star (neato -nop)", "Star (neato -nop2)", "twopi"]
    }
    
    public var readableName : String {
        return GVLayoutEngine.readableNames[self.rawValue]
    }
    
    public var graphvizName: String {
        switch self {
        case .dot: return "dot"
        case .neato: return "neato"
        case .fdp: return "fdp"
        case .nop: return "nop"
        case .nop2: return "nop2"
        case .twopi: return "twopi"
        default: return "unknown"
        }
    }
    public var supportsLayers: Bool {
        return self != .neato
    }
}

///marked as @objc in order to be able to save it as a simple scalar in core data / NSManagedObject
@objc public enum GVNodeShape : Int, Equatable , Codable, CaseIterable {
    case box = 0
    case circle = 1
    
    var graphvizName: String {
        switch self {
        case .box:
            return "box"
        case .circle:
            return "circle"
        }
    }
    
    public static var readableNames: [String] {
        return ["Rectangle", "Circle"]
    }
    
}

@objc public enum GVGraphType : Int, CaseIterable {
    case nonStrictDirected = 0
    case strictDirected
    case nonStrictNonDirected
    case strictNonDirected
    
    public var graphvizValue : Agdesc_t {
        switch self {
        case .nonStrictDirected: return Agdirected
        case .strictDirected : return Agstrictdirected
        case .nonStrictNonDirected: return Agundirected
        case .strictNonDirected: return Agstrictundirected
        }
    }
    
    public var readableName : String {
        return GVGraphType.readableNames[self.rawValue]
    }
    
    public static var readableNames: [String] {
        return ["Non-Strict Directed", "Strict Directed", "Non-Strict Non-Directed", "Strict Non-Directed"]
    }
    
    public var isStrict: Bool {
        switch self {
        case .nonStrictDirected, .nonStrictNonDirected : return false
        case .strictDirected, .strictNonDirected : return true
        }
    }
    
    public var isDirected: Bool {
        switch self {
        case .nonStrictDirected, .strictDirected : return true
        case .nonStrictNonDirected, .strictNonDirected : return false
        }
    }
}

@objc public enum GVModelDirection: Int , CaseIterable{
    case towardsLeft = 0
    case towardsRight
    case towardsTop
    case towardsBottom
    
    public var isVertical: Bool{
        return self == .towardsTop || self == .towardsBottom
    }
    
    public var isHorizontal: Bool{
        return self == .towardsLeft || self == .towardsRight
    }
    
    
    public static func fromGraphvizName(value: String) -> GVModelDirection {
        if value == "RL" {
            return .towardsLeft
        }
        if value == "TB" {
            return .towardsBottom
        }
        if value == "LR" {
            return .towardsRight
        }
        if value == "BT" {
            return .towardsTop
        }
        fatalError()
    }
    
    public var graphvizName: String {
        switch self {
        case .towardsLeft:
            return "RL"
        case .towardsBottom:
            return "TB"
        case .towardsRight:
            return "LR"
        case .towardsTop:
            return "BT"
        default:
            logger.warning("Unknown GVModelDirection : \(self.rawValue)")
            return "LR"
        }
    }
    var graphvizTailPort: String {
        switch self {
        case .towardsLeft:
            return "w"
        case .towardsBottom:
            return "s"
        case .towardsRight:
            return "e"
        case .towardsTop:
            return "n"
        }
    }
    
    public var graphvizHeadPort: String {
        switch self {
        case .towardsLeft:
            return "e"
        case .towardsBottom:
            return "n"
        case .towardsRight:
            return "w"
        case .towardsTop:
            return "s"
        }
    }
    
    public func isOpposite(other: GVModelDirection) -> Bool {
        return other == self.opposite
    }
    
    public var opposite : GVModelDirection {
        switch self {
        case .towardsLeft:
            return  .towardsRight
        case .towardsBottom:
            return .towardsTop
        case .towardsRight:
            return  .towardsLeft
        case .towardsTop:
            return .towardsBottom
        }
    }
    
    public func isSameDirection(other: GVModelDirection) -> Bool {
        switch self {
        case .towardsLeft:
            return other == .towardsLeft
        case .towardsBottom:
            return other == .towardsBottom
        case .towardsRight:
            return other == .towardsRight
        case .towardsTop:
            return other == .towardsTop
        }
    }
    
    public func is90Degrees(to: GVModelDirection) -> Bool {
        switch self {
        case .towardsLeft:
            return to == .towardsBottom
        case .towardsBottom:
            return to == .towardsRight
        case .towardsRight:
            return to == .towardsTop
        case .towardsTop:
            return to == .towardsLeft
        }
    }
    
    public static var readableNames: [String] {
        return ["Right to Left", "Left to Right", "Bottom to Top", "Top to Bottom", "MindMap"]
    }
    
    public var readableName : String {
        return GVModelDirection.readableNames[self.rawValue]
    }
}

@objc public enum GVClusterLabelPos: Int , CaseIterable{
    case topLeft = 0
    case topRight
    case bottomLeft
    case bottomRight
    
    static var readableNames: [String] {
        return ["Top-Left", "Top-Right", "Bottom-Left", "Bottom-Right"]
    }
    
    public var readableName : String {
        return GVClusterLabelPos.readableNames[self.rawValue]
    }
}

/// Make Graphviz more chatty. Call only if needed
/// Based on http://stackoverflow.com/questions/29469158/interact-with-legacy-c-terminal-app-from-swift
public func verboseGraphviz() {
    //        let args = ["dot", "-v", "-llibvplugin_dot_layout.6.dylib"]
    let args = ["dot", "-v"]
    // Create [UnsafeMutablePointer<Int8>]:
    var cargs = args.map {
        strdup($0)
        } + [nil]
    // Call C function:
    _ = gvParseArgs(gblGVContext, Int32(args.count), &cargs)
    // Free the duplicated strings:
    for ptr in cargs {
        if let ptr = ptr {
            free(ptr)
        }
    }
}


/// Needs to be called once before closing down the application
public func finishGraphviz() {
    gvFreeContext(gblGVContext)
}

/// Taking a string and creating a `char*` for calling a C function
///
/// **WARNING**
///   1. Don't destroy the orignal string before the result is handed over to the C funtion.
///   2. Don't use it if the String reference is kept on C side.
func cString(_ s: String) -> CHAR {
    return UnsafeMutablePointer<Int8>(mutating: (s as NSString).utf8String!)
}



@objc public enum GraphBias: Int64, CaseIterable {
    case fletchingSide = 0 // Graphviz default
    case pointySide = 1

    public static var readableNames: [String] {
        return ["Source Model Direction", "Target Model Direction"]
    }

    public static var toolTips: [String] {
        return ["If in doubt, then place the nodes as far as possible towards the backside of the graphs arrows (the side where the fletchings would be at a real arrow).", "If in doubt, then place the nodes as far as possible towards the pointy side of the graphs arrows"]
    }

    public var readableName: String {
        return GraphBias.readableNames[Int(self.rawValue)]
    }
}


public typealias GVParams = [GVParameter: String]

public protocol GraphBuilder {
    func newNode(name: String, label: String, cluster: GVCluster?) -> GVNode
    /// can return nil for strict graphs
    func newEdge(from: GVNode, to: GVNode, name: String, dir: GVEdgeParamDir) -> GVEdge?
    func newCluster(name: String, label: String, parent: GVCluster?) -> GVCluster
    func setNodeSize(node: GVNode, width: GVPixel, height: GVPixel)
    func setFontSize(node: GVNode, fontSize: CGFloat)
    func setNodeShape(node: GVNode, shape: GVNodeShape)
    
    func setBaseValue(param: GVParameter, value: String)
    func setBaseValues(_ params: GVParams)
    func setNodeValue(_ node: GVNode, _ param: GVNodeParameters, _ value: String)
    func setEdgeValue(_ edge: GVEdge,_ param: GVEdgeParameters, _ value: String)
    func setGraphValue(_ param: GVGraphParameters, _ value: String)
    func setClusterValue(_ cluster: GVCluster, _ param: GVGraphParameters, _ value: String)
    
    func getGraphRect() -> CGRect
    
    func layout( )
    var graph: GVGraph {get}
}

extension GraphBuilder {
    public func setBaseValues(_ params: GVParams) {
        for p in params.keys {
            if let value = params[p] {
                setBaseValue(param: p, value: value)
            }
        }
    }
}

public class GraphvizGraph: GraphBuilder {
    
    public enum Elements: Int32 {
        case graph = 0
        case node = 1
        case edge = 2
        
        static var readableNames: [String] {
            return ["graph", "node", "edge"]
        }
        
        var readableName: String {
            return GraphvizGraph.Elements.readableNames[Int(self.rawValue)]
        }
    }
    
    public enum SearchOrCreate : Int32 {
        case searchForExisting = 0
        case createNew = 1
    }
    
    #if DEBUG
    var baseValues :[Elements: Set<String> ] = [.graph : Set<String>(), .node: Set<String>(), .edge: Set<String>()]
    //    var baseEdgeValues = Set<GVEdgeParameters>()
    #endif
    
    /// reference to the graph structure that is used by graphviz
    private var g: GVGraph
    private var layouter: GVLayoutConfig
    
    /// see http://graphviz.org/doc/schema/attributes.xml for more attributes
    public init(name: String, type: GVGraphType, layouter: GVLayoutConfig) {
        g = agopen(cString(name), type.graphvizValue, nil);
        self.layouter = layouter
    }
    
    public var graph: GVGraph {
        return g
    }
    
    /// Simple Wrapper around `agattr` function of graphviz to set variables
    private func setBaseValue(_ target: Elements, _ attributeName: String, _ value: String) {
        #if DEBUG
        if baseValues[target]!.contains(attributeName) {
            logger.warning("baseValue already set for  \(attributeName) for \(target)")
        }
        #endif
        agattr(g, target.rawValue, cString(attributeName), cString(value))
        #if DEBUG
        baseValues[target]!.insert(attributeName)
//        Swift.print("setBaseValue \(target.debugName).\(attributeName) = \(value)")
        #endif
    }
    
    public func setBaseValue(param: GVParameter, value: String) {
        switch param {
        case .edge(let ep):
            setBaseValue(.edge, ep.rawValue, value)
        case .node(let np):
            setBaseValue(.node, np.rawValue, value)
        case .graph(let gp):
            setBaseValue(.graph, gp.rawValue, value)
        }
    }
    
    /// reminder: if attribute doesn't show effect then you have forgotten to set base value
    public func setNodeValue(_ node: GVNode, _ param: GVNodeParameters, _ value: String) {
        #if DEBUG
        if !baseValues[.node]!.contains(param.rawValue) {
            logger.error("no baseValue set for  \(param.rawValue) for Nodes. Setting the attribute Value will have no effect.")
        }
        #endif
        agset(node, cString(param.rawValue), cString(value))
    }
    
    /// reminder: if attribute doesn't show effect then you most likely have forgotten to set base value
    public func setEdgeValue(_ edge: GVEdge,_ param: GVEdgeParameters, _ value: String) {
        #if DEBUG
        if !baseValues[.edge]!.contains(param.rawValue) {
            logger.error("no baseValue set for  \(param.rawValue) for Edges. Setting the attribute Value will have no effect.")
        }
        #endif
        // setEdgeValue(edge, param.rawValue, value)
        agset(edge, cString(param.rawValue), cString(value))
    }
    
    /// reminder: if attribute doesn't show effect then you have forgotten to set base value
    public func setGraphValue(_ param: GVGraphParameters, _ value: String) {
        let attributeName = param.rawValue
        #if DEBUG
        if !baseValues[.graph]!.contains(attributeName) {
            logger.error("no baseValue set for  \(attributeName) for Graphs. Setting the attribute Value will have no effect.")
        }
        #endif
        agset(g, cString(attributeName), cString(value))
    }
    
    /// reminder: if attribute doesn't show effect then you have forgotten to set base value
    public func setClusterValue(_ cluster: GVCluster, _ param: GVGraphParameters, _ value: String) {
        let attributeName = param.rawValue
        #if DEBUG
        if !baseValues[.graph]!.contains(attributeName) {
            logger.error("no baseValue set for  \(attributeName) for Clusters. Setting the attribute Value will have no effect.")
        }
        #endif
        agset(cluster, cString(attributeName), cString(value))
    }
    deinit {
        //        Swift.print("GraphvizGraph.deinit")
        /* Free data */
        gvFreeLayout(gblGVContext, g)
        agclose(g)
    }
    
    public func newNode(name: String, label: String, cluster: GVCluster? = nil) -> GVNode {
        let graph = cluster ?? g
        let node = agnode(graph, cString(name), SearchOrCreate.createNew.rawValue) as GVNode
        setNodeValue(node, .label, label)
        return node
    }
    
    public func newEdge(from: GVNode, to: GVNode, name: String, dir: GVEdgeParamDir) -> GVEdge? {
        if let result = agedge(g, from, to, cString(name), SearchOrCreate.createNew.rawValue) {
            setEdgeValue(result, .dir, dir.rawValue)
            return result
        }
        return nil
    }
    
    public func newCluster(name: String, label: String, parent: GVCluster?) -> GVCluster {
        let p = parent ?? g
        let result = agsubg(p, cString("cluster\(name)"), SearchOrCreate.createNew.rawValue)!
        setClusterValue(result, GVGraphParameters.label, label)
        setClusterValue(result, GVGraphParameters.margin, "8")
        setClusterValue(result, GVGraphParameters.fontsize, "15")
        setClusterValue(result, GVGraphParameters.fontname, stdFontNameBold)
        return result
    }
    
    public func setSameRank(nodes: [String]){
        let sameNodes = nodes.reduce("same;", {prev, n in return "\(prev) \(n);"})
        agset(g, cString("rank"), cString(sameNodes))
    }
    
    public func setNodeSize(node: GVNode, width: GVPixel, height: GVPixel) {
        setNodeValue(node, GVNodeParameters.width , pixelToInchParameter(width))
        setNodeValue(node, .height, pixelToInchParameter(height))
        
    }
    
    public func setFontSize(node: GVNode, fontSize: CGFloat) {
        setNodeValue(node, .fontname, "\(fontSize)")
    }
    
    public func setNodeShape(node: GVNode, shape: GVNodeShape){
        setNodeValue(node, .shape, shape.graphvizName)
    }
    
    ///return size of
    public func getGraphRect() -> CGRect {
        let box = gd_bb (g)
        return CGRect(box: box)
    }
    
    public func layout( ){
        layouter.layout(gblGVContext, g)
    }
    
    public func saveTo(fileName: String) {
        g.saveTo(fileName: fileName)
    }
    
}
