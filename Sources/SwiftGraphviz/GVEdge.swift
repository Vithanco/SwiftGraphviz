//
//  GVEdge.swift
//  SwiftGraphiz
//
//  Created by Klaus Kneupner on 13/01/2019.
//  Copyright © 2019 Klaus Kneupner. All rights reserved.
//

import Foundation


public typealias GVEdge = UnsafeMutablePointer<Agedge_t>

public extension UnsafeMutablePointer where Pointee == Agedge_t {
    
    
    var labelPos: CGPoint? { //lp
        if let lPos = ed_lp(self) {
            return convertZeroPointToNil(CGPoint(gvPoint: lPos.pointee))
        }
        return nil
    }
    var headLabelPos:CGPoint? {
        if let lPos = ed_head_lp(self) {
            return convertZeroPointToNil(CGPoint(gvPoint: lPos.pointee))
        }
        return nil
    }
    var tailLabelPos:CGPoint? {
        if let lPos = ed_tail_lp(self) {
            return convertZeroPointToNil(CGPoint(gvPoint: lPos.pointee))
        }
        return nil
    }
    
    var labelText: String? {
        if let text = ed_label_text(self) {
            return String(cString: text)
        }
        return nil
    }
    
    var headLabelText: String? {
        if let text = ed_head_label_text(self) {
            return String(cString: text)
        }
        return nil
    }
    
    var tailLabelText: String? {
        if let text = ed_tail_label_text(self) {
            return String(cString: text)
        }
        return nil
    }
    
    var spline: GVSplines? {
        guard let t = pointee.base.data else {
            return nil
        }
        guard let spline = t.withMemoryRebound(to: Agedgeinfo_t.self, capacity: 1, {return $0.pointee.spl})  else {
            return nil
        }
        if spline.pointee.size != 1 {
            logThis(.warning, "an edge with size == \(spline.pointee.size)")
        }
        return spline
    }
    
    func getPath() throws -> [CGPoint]  {
        guard let spline = spline, let bezier = spline.pointee.list else {  //warning! this could be an array, see warning log in var spine: GVSlines?
            throw GraphvizError.noPath
        }
        let nrPoints = Int(bezier.pointee.size)
        let pointer = UnsafeRawPointer(bezier.pointee.list).bindMemory(to: pointf_s.self, capacity: nrPoints)
        var points: [pointf_s] = []
        for i in 0..<nrPoints {
            points.append(pointer[i])
        }
        return points.map(pointTransformGraphvizToCGPoint)
    }
    
    var arrowHead: CGPoint? {
        guard let spline = spline, let bezier = spline.pointee.list else {
            fatalError()
            
        }
        let result = bezier.pointee.ep
        return convertZeroPointToNil(pointTransformGraphvizToCGPoint(result))
    }
    
    var arrowTail: CGPoint? {
        guard let spline = spline, let bezier = spline.pointee.list else {
            fatalError()
        }
        let result = bezier.pointee.sp
        return convertZeroPointToNil(pointTransformGraphvizToCGPoint(result))
    }
    
    var headPortPos: CGPoint {
        return pointTransformGraphvizToCGPoint(ed_headPort_pos(self))
    }
    
    var tailPortPos: CGPoint {
        return pointTransformGraphvizToCGPoint(ed_tailPort_pos(self))
    }
    

}

