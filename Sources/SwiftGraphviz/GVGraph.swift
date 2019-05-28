//
//  GVGraph.swift
//  SwiftGraphvizIOS
//
//  Created by Klaus Kneupner on 27/05/2019.
//  Copyright © 2019 Klaus Kneupner. All rights reserved.
//

import Foundation



public typealias GVGraph = UnsafeMutablePointer<Agraph_t>

public extension UnsafeMutablePointer where Pointee == Agraph_t {
    
    func saveTo(fileName: String)  {

        
        let f = fopen(cString(fileName), cString("w"))
        agwrite(self,f)
        fsync(fileno(f))
        fclose(f)
//        println("success: \(success)")
        
    }

}
