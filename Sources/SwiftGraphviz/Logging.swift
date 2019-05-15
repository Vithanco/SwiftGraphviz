//
//  Logging.swift
//  Vithanco IBIS
//
//  Created by Klaus Kneupner on 15/10/2018.
//  Copyright © 2018 Klaus Kneupner. All rights reserved.
//

import os.log
import Cocoa

enum LogType {
    case debug
    case info
    case warning
    case error
}

@available(macOS 10.14, *)
fileprivate let logger = OSLog(subsystem:"com.vithanco",category:"SwiftGraphviz")


func logThis(_ type: LogType, _ text: String, uiText: String? = nil){
    if #available(macOS 10.14, *) {
        switch (type) {
        case .debug:
            os_log(OSLogType.debug, log: logger, "%@", text)
        case .info:
            os_log(OSLogType.default, log: logger, "%@", text)
        case .warning:
            os_log(OSLogType.info, log: logger, "%@", text)
        case .error:
            os_log(OSLogType.error, log: logger, "%@", text)
        }
    } else {
        Swift.print("\(type): \(text)")
    }
//    DispatchQueue.main.async {
//        let showText = uiText ?? text
//        if let bottomBar = vtApp().currentCanvasView()?.bottomBar {
//            switch (type) {
//            case .info :
//                bottomBar.stringValue = showText
//                bottomBar.textColor = NSColor.gray
//            case .warning:
//                bottomBar.stringValue = showText
//                bottomBar.textColor = rgb(153, 153, 0)
//                Swift.print(text)
//            case .error:
//                bottomBar.stringValue = showText
//                bottomBar.textColor = NSColor.systemRed
//                Swift.print(text)
//            case .debug:
//                break
//            }
//        }
//    }
}
