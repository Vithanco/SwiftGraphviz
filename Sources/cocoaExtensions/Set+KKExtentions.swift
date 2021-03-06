//
//  Set+KKExtentions.swift
//  Vithanco IBIS
//
//  Created by Klaus Kneupner on 11/08/2018.
//  Copyright © 2018 Klaus Kneupner. All rights reserved.
//

import Foundation


internal extension Set {
    var asArray: [Element] {
        return Array(self)
    }
}

internal extension Array where Element : Hashable {
    var asSet: Set<Element> {
        return Set<Element>(self)
    }
}
