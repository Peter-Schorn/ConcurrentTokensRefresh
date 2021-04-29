import Foundation
#if canImport(Combine)
import Combine
#else
import OpenCombine
import OpenCombineDispatch
import OpenCombineFoundation
#endif

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

#if canImport(Combine)
typealias ResultPublisher<Success, Failure: Error> =
    Result<Success, Failure>.Publisher
#else
typealias ResultPublisher<Success, Failure: Error> =
    Result<Success, Failure>.OCombine.Publisher
#endif

//extension DispatchQueue {
//    
//    #if canImport(Combine)
//    static func combineGlobal(
//        qos: DispatchQoS.QoSClass = .default
//    ) -> DispatchQueue {
//        return DispatchQueue.global(qos: qos)
//    }
//    #else
//    static func combineGlobal(
//        qos: DispatchQoS.QoSClass = .default
//    ) -> DispatchQueue.OCombine {
//        return DispatchQueue.global(qos: qos).ocombine
//    }
//    #endif
//    
//    #if canImport(Combine)
//    static func ocombine(label: String) -> DispatchQueue {
//        return DispatchQueue(label: label)
//    }
//    #else
//    static func ocombine(label: String) -> DispatchQueue.OCombine {
//        return DispatchQueue(label: label).ocombine
//    }
//    #endif
//  
//    #if canImport(Combine)
//    var queue: DispatchQueue { self }
//    #endif
//
//}
//
//extension URLSession {
//    
//    #if canImport(Combine)
//    static let combineShared = URLSession.shared
//    #else
//    static let combineShared = URLSession.shared.ocombine
//    #endif
//    
//}
