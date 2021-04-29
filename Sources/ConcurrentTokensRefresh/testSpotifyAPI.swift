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

func testSpotifyAPI() {
    
    let dispatchGroup = DispatchGroup()
    let internalQueue = DispatchQueue.ocombine(label: "internal")
    let concurrentQueue = DispatchQueue.ocombine(label: "concurrent")
    
    let spotifyAPI = SpotifyAPI()
    
    for i in 0..<1_000 {
        
        spotifyAPI.testMakeTokenExpired()
        
        print("\n--- \(i) ---\n")
        
        var cancellables: Set<AnyCancellable> = []
        var didChangeCount = 0
        spotifyAPI.tokenDidChange
            .receive(on: internalQueue)
//            .print("tokenDidChange sink")
            .sink {
                didChangeCount += 1
                print("didChangeCount += 1: \(didChangeCount)")
            }
            .store(in: &cancellables)
        
        concurrentQueue.queue.sync {
            DispatchQueue.concurrentPerform(iterations: 10) { i in
                
                print("\nconcurrent i: \(i)\n")
                
//                if i > 5 && Bool.random() {
//                    usleep(UInt32.random(in: 1_000...10_000))
//                }
                
                for _ in 0...10 {
                    dispatchGroup.enter()
                    let cancellable = spotifyAPI.album()
                        .sink(
                            receiveCompletion: { completion in
                                switch completion {
                                    case .finished:
                                        break
                                    case .failure(let error):
                                        fatalError(
                                            "publisher finished with error: \(error)"
                                        )
                                }
                                dispatchGroup.leave()
                            },
                            receiveValue: { album in
                                //                        print("recieved album: \(album)")
                            }
                        )
                    
                    internalQueue.queue.async {
                        cancellables.insert(cancellable)
                    }
                }
                
            }
        }
        dispatchGroup.wait()
        
        assert(didChangeCount == 1, "\(didChangeCount)")
        
    }
    
}
