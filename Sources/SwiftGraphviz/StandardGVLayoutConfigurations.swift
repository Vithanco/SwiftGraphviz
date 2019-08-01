//
//  File.swift
//  Vithanco
//
//  Created by Klaus Kneupner on 24/11/2018.
//  Copyright © 2018 Klaus Kneupner. All rights reserved.
//

import Foundation



@objc public enum StandardGVLayoutConfigurations : Int, CaseIterable {
    public static var saveGVOutput = false
    
    case dot = 0
    case neato
    case fdp
    case nop
    case nop2
    case twopi
    case systemsThinking
    
    public var configuration: GVLayoutConfig {
        switch self {
        case .dot:
            return GVLayoutConfig(
                name: "Layered (Dot)",
                layoutEngine: .dot,
                renderEngine: .dot,
                saveGVOutput: StandardGVLayoutConfigurations.saveGVOutput,
                params: [:],
                secondLayoutEngine: nil,
                supportClusters: true)
        case .neato:
            return GVLayoutConfig(
                name: "Star (neato)",
                layoutEngine: .neato,
                renderEngine: .dot,
                saveGVOutput: StandardGVLayoutConfigurations.saveGVOutput,
                params: [.graph(.overlap):GVParamValueOverlap.scale.rawValue], //,.graph(.sep): "+20,20"],
                secondLayoutEngine: nil,
                supportClusters: false)
        case .fdp:
            return GVLayoutConfig(
                name: "Star (fdp)",
                layoutEngine: .fdp,
                renderEngine: .dot,
                saveGVOutput: StandardGVLayoutConfigurations.saveGVOutput,
                params: [:],
                secondLayoutEngine: nil,
                supportClusters: true)
        case .nop:
            return GVLayoutConfig(
                name: "nop",
                layoutEngine: .dot,
                renderEngine: .nop,
                saveGVOutput: StandardGVLayoutConfigurations.saveGVOutput,
                params: [:],
                secondLayoutEngine: nil,
                supportClusters: true)
        case .nop2:
            return GVLayoutConfig(
                name: "nop2",
                layoutEngine: .dot,
                renderEngine: .nop2,
                saveGVOutput: StandardGVLayoutConfigurations.saveGVOutput,
                params: [:],
                secondLayoutEngine: nil,
                supportClusters: true)
        case .twopi:
            return GVLayoutConfig(
                name: "twopi",
                layoutEngine: .twopi,
                renderEngine: .dot,
                saveGVOutput: StandardGVLayoutConfigurations.saveGVOutput,
                params: [.graph(.overlap):GVParamValueOverlap.scale.rawValue],
                secondLayoutEngine: nil,
                supportClusters: false)
        case .systemsThinking:
            return GVLayoutConfig(
                name: "SystemsThinking",
                layoutEngine: .neato,
                renderEngine: .neato,
                saveGVOutput: StandardGVLayoutConfigurations.saveGVOutput,
                params: [.graph(.overlap):GVParamValueOverlap.scale.rawValue,.graph(.sep):"+20",.edge(.len):"3"],
                secondLayoutEngine: nil,
                supportClusters: false)
        }
    }
    public static var readableNames : [String] {
        return self.allCases.map({c in return c.configuration.name})
    }
    
    public var usesNodeDistance: Bool {
        return configuration.usesNodeDistance
    }
}
