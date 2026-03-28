//
//  GVGraph.swift
//  SwiftGraphvizIOS
//
//  Created by Klaus Kneupner on 27/05/2019.
//  Copyright © 2019 Klaus Kneupner. All rights reserved.
//

import Foundation
import GraphvizBridge


public typealias GVGraph = UnsafeMutablePointer<Agraph_t>

public struct AGWriteWrongEncoding: Error { }
public struct CannotOpenFileDescriptor: Error { }

public extension UnsafeMutablePointer where Pointee == Agraph_t {

    // MARK: - Attribute helpers

    /// Register a default attribute value on this graph. Must be called before `set(_:_:)` on individual elements.
    ///
    /// Usage:
    /// ```swift
    /// g.setDefault(.node(.label))
    /// g.setDefault(.edge(.dir), value: "forward")
    /// g.setDefault(.graph(.rankdir), value: "LR")
    /// ```
    func setDefault(_ param: GVParameter, value: String = "") {
        let kind: Int32
        let name: String
        switch param {
        case .node(let p):  kind = Int32(AGNODE);  name = p.rawValue
        case .edge(let p):  kind = Int32(AGEDGE);  name = p.rawValue
        case .graph(let p): kind = Int32(AGRAPH);  name = p.rawValue
        }
        let cName = strdup(name)
        let cVal = strdup(value)
        agattr(self, kind, cName, cVal)
        free(cName)
        free(cVal)
    }

    /// Set a graph-level attribute value.
    func set(_ param: GVGraphParameters, _ value: String) {
        let cName = strdup(param.rawValue)
        let cVal = strdup(value)
        agset(self, cName, cVal)
        free(cName)
        free(cVal)
    }

    /// Get a graph-level attribute value.
    func get(_ param: GVGraphParameters) -> String {
        let cName = strdup(param.rawValue)
        defer { free(cName) }
        if let result = agget(self, cName) {
            return String(cString: result)
        }
        return ""
    }

    // MARK: - I/O

    func saveTo(fileName: String) {
        fileName.withCString { nameCStr in
            "w".withCString { modeCStr in
                guard let f = fopen(nameCStr, modeCStr) else { return }
                agwrite(self, f)
                fsync(fileno(f))
                fclose(f)
            }
        }
    }

    /// adapted from: https://stackoverflow.com/questions/59653517/how-to-use-file-descriptor-to-divert-write-to-file-in-swift/59654364#59654364
    var asString: String? {
        let pipe = Pipe()
        do {
            try use(fileDescriptor: pipe.fileHandleForWriting.fileDescriptor, mode: "w") { filePointer in
                agwrite(self, filePointer)
            }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else {
                return nil
            }
            return output
        } catch {
            return nil
        }
    }

    func unflatten(doFan: Bool = false, maxMinlen: Int32 = 0, chainLimit: Int32 = 0) {
        agUnflatten(self, doFan ? 1 : 0, maxMinlen, chainLimit)
    }
}

@discardableResult
fileprivate func use<R>(
    fileDescriptor: Int32,
    mode: UnsafePointer<Int8>!,
    closure: (UnsafeMutablePointer<FILE>) throws -> R
) throws -> R {
    guard let filePointer = fdopen(fileDescriptor, mode) else {
        throw CannotOpenFileDescriptor()
    }
    defer {
        fclose(filePointer)
    }
    return try closure(filePointer)
}
