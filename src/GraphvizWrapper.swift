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
}

public typealias GVGraph = UnsafeMutablePointer<Agraph_t>


///Global Graphviz Context.
///To be set at program start and freed and progam end
fileprivate var gblGVContext: GVGlobalContextPointer = loadGraphvizLibraries() //UnsafeMutablePointer<GVC_t>?


public typealias CHAR = UnsafeMutablePointer<Int8>
public typealias CHAR_ARRAY = UnsafeMutablePointer<UnsafeMutablePointer<Int8>>
public typealias GVSplines = UnsafeMutablePointer<splines>
public typealias GVBezier = UnsafeMutablePointer<bezier>
public typealias GVPixel = CGFloat
public typealias GVGlobalContextPointer = OpaquePointer?


func convertZeroPointToNil(_ gvPos: CGPoint) -> CGPoint? {
    if gvPos.distance(to: NSZeroPoint) < 0.1 {
        return nil
    }
    return gvPos
}

func pointTransformGraphvizToCGPoint(_ point: pointf_s) -> CGPoint {
    return CGPoint(gvPoint: point)
}

extension CGPoint {
    init (gvPoint: pointf_s) {
        self.init(x: CGFloat(gvPoint.x), y: CGFloat(gvPoint.y))
        assert (isFinite)
    }
}

extension CGRect {
    init (box: boxf) {
        self.init(x: box.LL.x, y: box.LL.y, width: box.UR.x - box.LL.x, height: box.UR.y - box.LL.y)
    }
}


@objc public enum GraphLogic: Int64, CaseIterable {
    case noLogic = 0
    case sufficientCause
    case necessaryCondition
    
    static var readableNames: [String] {
        return ["None", "Sufficient Cause" ,"Necessary Condition"]
    }
    
    static var toolTips: [String] {
        return ["Don't use any particular logic", "'Sufficient Cause' logic means that each predecessor is enough (=sufficient) to achieve the successor. So, if any predcessor is valid then the successors are valid, too." ,"'Necessary Condition' logic means that each predessor is needed to achieve the successor but not necessarily sufficient. So, only if all predessors are valid is the successor also valid."]
    }
    
    var asString: String {
        return GraphLogic.readableNames[Int(self.rawValue)]
    }
}

@objc public enum GVLayoutEngine: Int {
    case dot = 0
    case neato
    case fdp
    case nop
    case nop2
    case twopi
    

    
    static var readableNames: [String] {
        return ["Layered (dot)", "Star (neato)", "Star (fdp)", "Star (neato -nop)", "Star (neato -nop2)", "twopi", "Systems Thinking"]
    }
    
    var graphvizName: String {
        switch self {
        case .dot: return "dot"
        case .fdp: return "fdp"
        case .neato: return "neato"
        case .nop: return "nop"
        case .nop2: return "nop2"
        case .twopi: return "twopi"
        }
    }
}





///marked as @objc in order to be able to save it as a simple scalar in core data / NSManagedObject
@objc public enum GVNodeShape : Int {
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
    
    static var readableNames: [String] {
        return ["Rectangle", "Circle"]
    }
    
}

@objc public enum GVGraphType : Int {
    case nonStrictDirected = 0
    case strictDirected
    case nonStrictNonDirected
    case strictNonDirected
    
    var graphvizValue : Agdesc_t {
        switch self {
        case .nonStrictDirected: return Agdirected
        case .strictDirected : return Agstrictdirected
        case .nonStrictNonDirected: return Agundirected
        case .strictNonDirected: return Agstrictundirected
        }
    }
    
    var readableValue : String {
        return GVGraphType.readableNames[self.rawValue]
    }
    
    static var readableNames: [String] {
        return ["Non-Strict Directed", "Strict Directed", "Non-Strict Non-Directed", "Strict Non-Directed"]
    }
    
    var isStrict: Bool {
        switch self {
        case .nonStrictDirected, .nonStrictNonDirected : return false
        case .strictDirected, .strictNonDirected : return true
        }
    }
}

@objc public enum GVModelDirection: Int , CaseIterable{
    case towardsLeft = 0
    case towardsRight
    case towardsTop
    case towardsBottom
    
    
    var graphvizName: String {
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
            logThis(.warning, "Unknown GVModelDirection : \(self.rawValue)")
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
    
    var graphvizHeadPort: String {
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
    
    func isOpposite(other: GVModelDirection) -> Bool {
        switch self {
        case .towardsLeft:
            return other == .towardsRight
        case .towardsBottom:
            return other == .towardsTop
        case .towardsRight:
            return other == .towardsLeft
        case .towardsTop:
            return other == .towardsBottom
        }
    }
    
    func isSameDirection(other: GVModelDirection) -> Bool {
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
    
    func is90Degrees(to: GVModelDirection) -> Bool {
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
    
    static var readableNames: [String] {
        return ["Right to Left", "Left to Right", "Bottom to Top", "Top to Bottom", "MindMap"]
    }
}

@objc public enum GVClusterLabelPos: Int {
    case topLeft = 0
    case topRight
    case bottomLeft
    case bottomRight

    static var readableNames: [String] {
        return ["Top-Left", "Top-Right", "Bottom-Left", "Bottom-Right"]
    }
}


struct GVClusterPosData {
    let rect: CGRect
    let labelPos: CGPoint
    
    ///Hide the cluster if the layout engine doesn't support it 
    let isHidden: Bool
    
    func addToHeight(_ add: CGFloat) -> GVClusterPosData {
        return GVClusterPosData(rect: rect.addToHeight(add), labelPos: labelPos, isHidden: isHidden)
    }
}


func prepareGraphviz() {
//    gblGVContext = gvContext()
//    assert(gblGVContext.unsafelyUnwrapped != nil)
//    loadGraphvizLibraries(gblGVContext)
//          verboseGraphviz()

}

/// Make Graphviz more chatty. Call only if needed
/// Based on http://stackoverflow.com/questions/29469158/interact-with-legacy-c-terminal-app-from-swift
func verboseGraphviz() {
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
        free(ptr)
    }
}


/// Needs to be called once before closing down the application
func finishGraphviz() {
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


public protocol GraphSettings: class {
    var direction: GVModelDirection {get}
    var maxNodeWidth: Double {get}
    var maxNodeHeight: Double {get}
    var minNodeDistanceX: Double {get} //nodesep
    var minNodeDistanceY: Double {get} //ranksep
    var edgeStyle: GVEdgeStyle {get}
    var layouter: GVLayoutConfig {get}
    var graphType: GVGraphType {get}
    var maxNodeSize: CGSize {get}
    var nodeViewSize: CGSize {get}
    var logic: GraphLogic {get}
    var name: String? {get}
}

public class GraphvizGraph {
    
    enum Elements: Int32 {
        case graph = 0
        case node = 1
        case edge = 2
    }
    
    static let createNew : Int32 = 1
//    let edgeStyle: GVEdgeStyle
    
    #if DEBUG
    var baseValues :[Elements: Set<String> ] = [.graph : Set<String>(), .node: Set<String>(), .edge: Set<String>()]
//    var baseEdgeValues = Set<GVEdgeParameters>()
    #endif
    
    /// reference to the graph structure that is used by graphviz
    private var g: GVGraph
    
    /// see http://graphviz.org/doc/schema/attributes.xml for more attributes
    init(name: String, type: GVGraphType, layouter: GVLayoutConfig) {
        
    
//        let name = graph.name ?? "unnamed Graph"
        
//        logThis(.debug, "layouting \(graphType.readableValue) graph")
        g = agopen(cString(name), type.graphvizValue, nil);
        
        layouter.setParams(self)
    }
    
    /// Simple Wrapper around `agattr` function of graphviz to set variables
    func setBaseValue(_ target: Elements, _ attributeName: String, _ value: String) {
        #if DEBUG
        if baseValues[target]!.contains(attributeName) {
            logThis(.warning, "baseValue already set for  \(attributeName) for \(target)")
        }
        #endif
        agattr(g, target.rawValue, cString(attributeName), cString(value))
        #if DEBUG
        baseValues[target]!.insert(attributeName)
        #endif
    }
    
    func setBaseValue(param: GVParameter, value: String) {
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
    func setNodeValue(_ node: GVNode, _ attributeName: String, _ value: String) {
        #if DEBUG
        if !baseValues[.node]!.contains(attributeName) {
            logThis(.error, "no baseValue set for  \(attributeName) for Nodes. Setting the attribute Value will have no effect.")
        }
        #endif
        agset(node, cString(attributeName), cString(value))
    }
    
//    /// reminder: if attribute doesn't show effect then you have forgotten to set base value
//    fileprivate func setEdgeValue(_ edge: GVEdge, _ attributeName: String, _ value: String) {
//
//        agset(edge, cString(attributeName), cString(value))
//    }
    
    /// reminder: if attribute doesn't show effect then you have forgotten to set base value
    func setEdgeValue(_ edge: GVEdge,_ param: GVEdgeParameters, _ value: String) {
        #if DEBUG
        if !baseValues[.edge]!.contains(param.rawValue) {
            logThis(.error, "no baseValue set for  \(param.rawValue) for Edges. Setting the attribute Value will have no effect.")
        }
        #endif
      // setEdgeValue(edge, param.rawValue, value)
        agset(edge, cString(param.rawValue), cString(value))
    }
    
    /// reminder: if attribute doesn't show effect then you have forgotten to set base value
    func setGraphValue(_ attributeName: String, _ value: String) {
        #if DEBUG
        if !baseValues[.graph]!.contains(attributeName) {
            logThis(.error, "no baseValue set for  \(attributeName) for Graphs. Setting the attribute Value will have no effect.")
        }
        #endif
        agset(g, cString(attributeName), cString(value))
    }
    
    /// reminder: if attribute doesn't show effect then you have forgotten to set base value
    func setClusterValue(_ cluster: GVCluster, _ attributeName: String, _ value: String) {
        #if DEBUG
        if !baseValues[.graph]!.contains(attributeName) {
            logThis(.error, "no baseValue set for  \(attributeName) for Clusters. Setting the attribute Value will have no effect.")
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
    
    func newNode(cluster: GVCluster?, name: String, label: String) -> GVNode {
        let graph = cluster ?? g
        let node = agnode(graph, cString(name), GraphvizGraph.createNew) as GVNode
        setNodeValue(node, "label", label)
        return node
    }
    
    func newEdge(from: GVNode, to: GVNode, name: String, dir: GVEdgeParamDir) -> GVEdge {
        let result = agedge(g, from, to, cString(name), GraphvizGraph.createNew)!
    
//        Swift.print("edge: weight= \(weight), constraint= \(constraint ? "true" : "false")")
        setEdgeValue(result, .dir, dir.rawValue)
        return result
    }
    
    func newCluster(name: String, label: String, parent: GVCluster?) -> GVCluster {
        let p = parent ?? g
        let result = agsubg(p, cString("cluster\(name)"), GraphvizGraph.createNew)!
        setClusterValue(result, "label", label)
        setClusterValue(result, "margin", "8")
        setClusterValue(result, "fontsize", "15")
        setClusterValue(result, "fontname", "Verdana-Bold")
        return result
    }
    
    func setSameRank(nodes: [String]){
        let sameNodes = nodes.reduce("same;", {prev, n in return "\(prev) \(n);"})
        agset(g, cString("rank"), cString(sameNodes))
    }
    
    func setNodeSize(node: GVNode, width: GVPixel, height: GVPixel) {
        setNodeValue(node, "width", pixelToInchParameter(width-2))
        setNodeValue(node, "height", pixelToInchParameter(height-2))
    }
    
    func setFontSize(node: GVNode, fontSize: CGFloat) {
        setNodeValue(node, "fontsize", "\(fontSize)")
    }
    
    func setNodeShape(node: GVNode, shape: GVNodeShape){
        setNodeValue(node, "shape", shape.graphvizName)
    }
    
    ///return size of
    func getGraphRect(cluster: GVCluster? = nil) -> CGRect {
        let graph = cluster ?? g // use global graph if not asking for particular cluster
        let box = gd_bb (graph)
        return CGRect(box: box)
    }
    
    func layout(engine: GVLayoutConfig) {
        engine.layout(gblGVContext, g)
    }
    
    func getClusterPos(cluster: GVCluster) -> GVClusterPosData{
        var rect = getGraphRect(cluster: cluster)
        rect = CGRect(origin: rect.origin, size: CGSize(width: rect.width, height: rect.height))
        
        let lblPos = cluster.labelPos ?? NSZeroPoint
        let result = GVClusterPosData(rect: rect, labelPos: lblPos, isHidden: false)
        return result
    }
    
}
