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

class SpotifyAPI {
    
    /**
     The request to refresh the access token is stored in this
     property so that if multiple asyncronous requests are made
     to refresh the access token, then only one actual network
     request is made. Once this publisher finishes, it is set to
     `nil`.
     */
    private var refreshTokensPublisher: AnyPublisher<Void, Error>? = nil

    private var internalQueue = DispatchQueue(
        label: "internalQueue"
    )
    
    private let externalQueue = DispatchQueue(label: "externalQueue")
    
    let tokenDidChange = PassthroughSubject<Void, Never>()

    var token: Token? = nil

    func testMakeTokenExpired() {
        self.internalQueue.sync {
            self.token?.expirationDate = Date()
            BackendServer.token?.expirationDate = Date()
        }
    }

    func refreshTokenIfExpired(i: Int) -> AnyPublisher<Void, Error> {
        
        return self.internalQueue.sync { () -> AnyPublisher<Void, Error>  in
                
            if let token = self.token, !token.isExpired() {
                print(
                    "\(i) refreshTokenIfExpired: access token not expired; " +
                    "returning early"
                )
                return ResultPublisher(())
                    .eraseToAnyPublisher()
            }
            
            print("\(i) refreshTokenIfExpired: access token is expired")
            
            if let publisher = self.refreshTokensPublisher {
                print("\(i) returning previous publisher")
                return publisher
            }
            
            print("\(i) refreshTokenIfExpired: creating new publisher")
            
            let refreshTokensPublisher = BackendServer.refreshToken(i: i)
                .receive(on: self.internalQueue)
                .map { token in
                    print("\(i) received token")
                    self.token = token
                    self.refreshTokensPublisher = nil
                    self.externalQueue.async {
                        self.tokenDidChange.send()
                        print("\(i) self.tokenDidChange.send()")
                    }
                }
                .handleEvents(receiveCompletion: { completion in
                    print("\(i) receive completion; refreshTokensPublisher = nil")
                    self.refreshTokensPublisher = nil
                })
                .share()
                .handleEvents(receiveOutput: { _ in
                    dispatchPrecondition(condition: .onQueue(self.internalQueue))
                })
                .receive(on: self.externalQueue)
                .eraseToAnyPublisher()

            self.refreshTokensPublisher = refreshTokensPublisher
            return refreshTokensPublisher

        }

    }

}

// MARK: Backend

/// Represents the Spotify Web API server.
class BackendServer {
    
    private static let internalQueue = DispatchQueue(
        label: "BackendServer.internal"
    )

    /// The currently valid token.
    static var token: Token? = nil

    static func refreshToken(i: Int) -> AnyPublisher<Token, Error> {

        return Self.internalQueue.sync {
            print("\(i) BackendServer.refreshToken")
            let accessToken = UUID().uuidString
            let expirationDate = Date().addingTimeInterval(5)
            let newToken = Token(
                accessToken: accessToken,
                expirationDate: expirationDate
            )
            Self.token = newToken

            return ResultPublisher<Token, Error>(newToken)
                .delay(
                    for: .milliseconds(Int.random(in: 100...1_000)),
                    scheduler: DispatchQueue.global()
                )
                .eraseToAnyPublisher()
        }

    }
}

struct Token {
    
    let accessToken: String
    var expirationDate: Date
    
    func isExpired() -> Bool {
        return self.expirationDate < Date()
    }
}
