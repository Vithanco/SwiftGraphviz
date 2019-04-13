//
//  GVNode.swift
//  Vithanco
//
//  Created by Klaus Kneupner on 15/01/2019.
//  Copyright © 2019 Klaus Kneupner. All rights reserved.
//

import Foundation


public typealias GVNode = UnsafeMutablePointer<Agnode_t>


extension UnsafeMutablePointer where Pointee == Agnode_t {

    var pos : CGPoint {
        let s = nd_coord(self)
        return CGPoint(gvPoint: s)
    }

}
