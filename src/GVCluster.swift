//
//  GVCluster.swift
//  Vithanco
//
//  Created by Klaus Kneupner on 15/01/2019.
//  Copyright © 2019 Klaus Kneupner. All rights reserved.
//

import Foundation


public typealias GVCluster = UnsafeMutablePointer<Agraph_t>


extension UnsafeMutablePointer where Pointee == Agraph_t {
    
    
    var labelPos: CGPoint? { //lp
        if let lPos = gd_lp(self) {
            return convertZeroPointToNil(CGPoint(gvPoint: lPos.pointee))
        }
        return nil
    }
}
