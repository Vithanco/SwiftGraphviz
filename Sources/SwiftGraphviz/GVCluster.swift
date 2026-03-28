//
//  GVCluster.swift
//  Vithanco
//
//  Created by Klaus Kneupner on 15/01/2019.
//  Copyright © 2019 Klaus Kneupner. All rights reserved.
//

import GraphvizBridge



public typealias GVCluster = UnsafeMutablePointer<Agraph_t>


public extension UnsafeMutablePointer where Pointee == Agraph_t {
    var labelPos: GVPoint? {
        if let lPos = gd_lp(self) {
            return convertZeroPointToNil(GVPoint(gvPoint: lPos.pointee))
        }
        return nil
    }

    var labelSize: GVSize? {
        if let lPos = gd_lsize(self) {
            return GVSize(gvPoint: lPos.pointee).convertZeroToNil()
        }
        return nil
    }

    var rect: GVRect {
        let box = gd_bb(self)
        return GVRect(box: box)
    }

    var labelText: String? {
        if let text = gd_label_text(self) {
            return String(cString: text)
        }
        return nil
    }
}
