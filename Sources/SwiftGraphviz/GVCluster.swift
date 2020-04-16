//
//  GVCluster.swift
//  Vithanco
//
//  Created by Klaus Kneupner on 15/01/2019.
//  Copyright © 2019 Klaus Kneupner. All rights reserved.
//

import Foundation


public protocol ClusterLayout {
    var labelPos: CGPoint? {get}
    var labelSize: CGSize? {get}
    var rect: CGRect {get}
}

struct ClusterLayoutImpl : ClusterLayout {
    let labelPos: CGPoint?
    let labelSize: CGSize?
    let rect: CGRect
}


public typealias GVCluster = UnsafeMutablePointer<Agraph_t>


public extension UnsafeMutablePointer where Pointee == Agraph_t {
    
    
    var labelPos: CGPoint? { //lp
        if let lPos = gd_lp(self) {
            return convertZeroPointToNil(CGPoint(gvPoint: lPos.pointee))
        }
        return nil
    }
    
    var labelSize: CGSize? { //lp
        if let lPos = gd_lsize(self) {
            return CGSize(gvPoint: lPos.pointee).convertZeroSizeToNil()
        }
        return nil
    }
    
    var rect: CGRect {
        let box = gd_bb (self)
        return CGRect(box: box)
    }
    
    var labelText: String? {
        if let text = gd_label_text(self) {
            return String(cString: text)
        }
        return nil
    }

    var asClusterLayout : ClusterLayout {
        return ClusterLayoutImpl(labelPos: labelPos, labelSize: labelSize, rect: rect)
    }
}
