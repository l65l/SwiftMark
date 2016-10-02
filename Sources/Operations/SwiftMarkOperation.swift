//
//  SwiftMarkOperation.swift
//  SwiftMark
//
//  Created by Pierre TACCHI on 13/01/16.
//  Copyright © 2016 Pierre TACCHI. All rights reserved.
//

import Foundation

public typealias ConversionCompleteBlock = (String) -> ()
public typealias FailureBlock = (SwiftMarkError) -> ()
 /// The `SwiftMarkOperation` class is the abstarct base class for all operation executed in order to convert *CommonMark* texts. Do not subclass or create instances of this class directly. Instead, create instances of one of its concrete subclasses.
 ///
 /// Use the properties of this class to configure the behavior of the operation object before submitting it to an operation queue or executing it directly.
open class SwiftMarkOperation: Operation {
    fileprivate let markdownText: String?
    fileprivate let fileURL: URL?
    fileprivate let encoding: UInt
    
        /// The options passed to the parser.
    open let options: SwiftMarkOptions
        /// The block to execute with the result of the conversion.
    open var conversionCompleteBlock: ConversionCompleteBlock?
        /// The block to execute when an error occurs.
    open var failureBlock: FailureBlock?

    internal init(text: String, options: SwiftMarkOptions = .Default) {
        self.markdownText = text
        self.options = options
        self.encoding = 0
        self.fileURL = nil
    }
    
    internal init(url: URL, options: SwiftMarkOptions = .Default, encoding: UInt = String.Encoding.utf8.rawValue) {
        self.markdownText = nil
        self.options = options
        self.encoding = encoding
        self.fileURL = url
    }
    
    override open func main() {
        guard !isCancelled else { return }
        guard let commonMarkString = try? commonMarkString() else {
            DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).sync {
                self.failureBlock?(SwiftMarkError.fileLoadingError)
            }
            return
        }
        guard !isCancelled else { return }
        guard let convertedString = try? convert(commonMarkString) else {
            DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).sync {
                self.failureBlock?(SwiftMarkError.parsingError)
            }
            return
        }
        DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).sync { 
            self.conversionCompleteBlock?(convertedString)
        }
    }
    
    internal func convert(_ commonMarkString: String) throws -> String {
        throw SwiftMarkError.parsingError
    }
    
    fileprivate func commonMarkString() throws -> String {
        if let commonMarkString = markdownText {
            return commonMarkString
        }
        guard let url = fileURL else { throw SwiftMarkError.fileLoadingError }
        return try loadCommonMarkFromURL(url, encoding: self.encoding)
    }
}
