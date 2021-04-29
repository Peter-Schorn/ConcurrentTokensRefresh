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
    let internalQueue = DispatchQueue(label: "internal")
    
    let spotifyAPI = SpotifyAPI()
    
    for i in 0..<1_000 {
        
        spotifyAPI.testMakeTokenExpired()
        
        print("\n--- \(i) ---\n")
        
        var cancellables: Set<AnyCancellable> = []
        var didChangeCount = 0
        spotifyAPI.tokenDidChange
            .receive(on: internalQueue)
            .sink {
                didChangeCount += 1
                print("didChangeCount += 1: \(didChangeCount)")
            }
            .store(in: &cancellables)
        
        DispatchQueue.concurrentPerform(iterations: 2) { i in
            
            print("\nconcurrent i: \(i)\n")
            
                dispatchGroup.enter()
                let cancellable = spotifyAPI.refreshTokenIfExpired(i: i)
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
                            internalQueue.asyncAfter(deadline: .now() + 1) {
                                print("completion \(i)")
                                dispatchGroup.leave()
                            }
                        },
                        receiveValue: { _ in }
                    )
                
                internalQueue.async {
                    cancellables.insert(cancellable)
                }
            
        }
        dispatchGroup.wait()
        
        assert(
            didChangeCount == 1,
            "didChangeCount should be 1, not \(didChangeCount)"
        )
            
        usleep(100_000)
        
    }
    
}
