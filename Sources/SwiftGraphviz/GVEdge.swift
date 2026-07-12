//
//  GVEdge.swift
//  SwiftGraphiz
//
//  Created by Klaus Kneupner on 13/01/2019.
//  Copyright © 2019 Klaus Kneupner. All rights reserved.
//

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#elseif canImport(WASILibc)
import WASILibc
#endif
import GraphvizBridge


public typealias GVEdge = UnsafeMutablePointer<Agedge_t>

public extension UnsafeMutablePointer where Pointee == Agedge_t {

    // MARK: - Attribute helpers

    /// Set an edge attribute value.
    func set(_ param: GVEdgeParameters, _ value: String) {
        let cName = strdup(param.rawValue)
        let cVal = strdup(value)
        agset(self, cName, cVal)
        free(cName)
        free(cVal)
    }

    // MARK: - Layout results

    var labelPos: GVPoint? {
        if let lPos = ed_lp(self) {
            return convertZeroPointToNil(GVPoint(gvPoint: lPos.pointee))
        }
        return nil
    }
    var headLabelPos: GVPoint? {
        if let lPos = ed_head_lp(self) {
            return convertZeroPointToNil(GVPoint(gvPoint: lPos.pointee))
        }
        return nil
    }
    var tailLabelPos: GVPoint? {
        if let lPos = ed_tail_lp(self) {
            return convertZeroPointToNil(GVPoint(gvPoint: lPos.pointee))
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
            assertionFailure("Unexpected: edge with spline size == \(spline.pointee.size)")
        }
        return spline
    }

    func getPath() throws -> [GVPoint]  {
        guard let spline = spline, let bezier = spline.pointee.list else {
            throw GraphvizError.noPath
        }
        let nrPoints = Int(bezier.pointee.size)
        let pointer = UnsafeRawPointer(bezier.pointee.list).bindMemory(to: pointf_s.self, capacity: nrPoints)
        var points: [pointf_s] = []
        for i in 0..<nrPoints {
            points.append(pointer[i])
        }
        return points.map(pointTransformToGVPoint)
    }

    var arrowHead: GVPoint? {
        guard let spline = spline, let bezier = spline.pointee.list else {
            fatalError()
        }
        return pointTransformToGVPoint(bezier.pointee.ep)
    }

    var arrowTail: GVPoint? {
        guard let spline = spline, let bezier = spline.pointee.list else {
            fatalError()
        }
        return pointTransformToGVPoint(bezier.pointee.sp)
    }

    var headPortPos: GVPoint {
        return pointTransformToGVPoint(ed_headPort_pos(self))
    }

    var tailPortPos: GVPoint {
        return pointTransformToGVPoint(ed_tailPort_pos(self))
    }

}
