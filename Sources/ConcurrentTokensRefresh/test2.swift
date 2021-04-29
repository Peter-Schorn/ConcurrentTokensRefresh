import Foundation
#if canImport(Combine)
import Combine
#else
import OpenCombine
import OpenCombineDispatch
import OpenCombineFoundation
#endif

func test2() {
    
    let dispatchGroup = DispatchGroup()
    let internalQueue = DispatchQueue.ocombine(label: "internal")
    
    _ = dispatchGroup

    var cancellables: Set<AnyCancellable> = []
    
    func makePublisher() -> AnyPublisher<Int, Never> {
        return internalQueue.queue.sync {
            Deferred { () -> AnyPublisher<Int, Never> in
                print("making publisher")
                let int = Int.random(in: 0...1_000_000)
                print("int: \(int)")
                return Just(int)
                    .delay(
                        for: .milliseconds(100),
                        scheduler: internalQueue
                    )
                    .eraseToAnyPublisher()
            }
            .share()
            .eraseToAnyPublisher()
        }
    }

    
    let publisher = makePublisher()

    print(#line)

    let concurrentQueue = DispatchQueue.ocombine(label: "concurrentQueue")
    _ = concurrentQueue
    

    concurrentQueue.queue.sync {
        
    DispatchQueue.concurrentPerform(iterations: 20) { i in
//        for i in 0..<2 {
            
            dispatchGroup.enter()
            let cancellable = publisher
//                .print("sink 1")
                .sink { int in
                    print("[sink \(i)] received value: \(int)")
                    dispatchGroup.leave()
                }
            
            internalQueue.queue.sync {
                _ = cancellables.insert(cancellable)
            }
            
        }
    }

    dispatchGroup.wait()
    
}
