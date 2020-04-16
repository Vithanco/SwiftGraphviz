//
//  GVGraph.swift
//  SwiftGraphvizIOS
//
//  Created by Klaus Kneupner on 27/05/2019.
//  Copyright © 2019 Klaus Kneupner. All rights reserved.
//

import Foundation

public typealias GVGraph = UnsafeMutablePointer<Agraph_t>

public struct AGWriteWrongEncoding: Error { }
public struct CannotOpenFileDescriptor: Error { }

public extension UnsafeMutablePointer where Pointee == Agraph_t {
    
    func saveTo(fileName: String)  {
        let f = fopen(cString(fileName), cString("w"))
        agwrite(self,f)
        fsync(fileno(f))
        fclose(f)
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
}

@discardableResult
fileprivate func use<R>(
    fileDescriptor: Int32,
    mode: UnsafePointer<Int8>!,
    closure: (UnsafeMutablePointer<FILE>) throws -> R
) throws -> R {
    // Should prob remove this `!`, but IDK what a sensible recovery mechanism would be.
    guard let filePointer = fdopen(fileDescriptor, mode) else {
        throw CannotOpenFileDescriptor()
    }
    defer {
        fclose(filePointer)
    }
    return try closure(filePointer)
}
