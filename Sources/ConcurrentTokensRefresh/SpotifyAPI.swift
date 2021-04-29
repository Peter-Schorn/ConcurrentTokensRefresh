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

    func refreshTokenIfExpired() -> AnyPublisher<Void, Error> {
        
        return self.internalQueue.sync { () -> AnyPublisher<Void, Error>  in
                
            if let token = self.token, !token.isExpired() {
//                print(
//                    "refreshTokenIfExpired: access token not expired; " +
//                    "returning early"
//                )
                return ResultPublisher(())
                    .eraseToAnyPublisher()
            }
            
//            print("refreshTokenIfExpired: access token is expired")
            
            if let publisher = self.refreshTokensPublisher {
//                print("returning previous publisher")
                return publisher
            }
            
            print("refreshTokenIfExpired: creating new publisher")
            
            let refreshTokensPublisher = BackendServer.refreshToken()
                .receive(on: self.internalQueue)
                .map { token in
                    self.token = token
                    self.refreshTokensPublisher = nil
                    print("self.tokenDidChange.send()")
                    self.tokenDidChange.send()
                }
                .handleEvents(receiveCompletion: { completion in
                    self.refreshTokensPublisher = nil
                })
                .share()
                .receive(on: self.externalQueue)
                .eraseToAnyPublisher()

            self.refreshTokensPublisher = refreshTokensPublisher
            return refreshTokensPublisher

        }

    }

    /// Request an album from the Spotify web API
    func album() -> AnyPublisher<Album, Error> {

        return self.refreshTokenIfExpired()
            .flatMap { () -> AnyPublisher<Album, Error> in
                guard let token = self.token else {
                    return Fail(error: SpotifyError.unauthorized)
                        .eraseToAnyPublisher()
                }
                return BackendServer.album(accessToken: token.accessToken)
            }
            .eraseToAnyPublisher()

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

    static func refreshToken() -> AnyPublisher<Token, Error> {

        return Self.internalQueue.sync {
            print("BackendServer.refreshToken")
            let accessToken = UUID().uuidString
            let expirationDate = Date().addingTimeInterval(5)
            let newToken = Token(
                accessToken: accessToken,
                expirationDate: expirationDate
            )
            Self.token = newToken

            return ResultPublisher<Token, Error>(newToken)
                .networkDelay()
        }

    }
    
    static func album(accessToken: String) -> AnyPublisher<Album, Error> {
        
        return Self.internalQueue.sync {
            
            do {
                guard let token = Self.token else {
                    throw SpotifyError.unauthorized
                }
                if token.isExpired() {
                    throw SpotifyError.expiredToken
                }
                if token.accessToken != accessToken {
                    throw SpotifyError.invalidToken
                }
                
                let album = Album(name: "The Dark Side of the Moon")
                
                return ResultPublisher(album)
                    .networkDelay()
                
            } catch {
                return Fail(error: error)
                    .networkDelay()
            }
        }

    }
    
}

enum SpotifyError: Error {
    case expiredToken
    case invalidToken
    case unauthorized
}

struct Token {
    
    let accessToken: String
    var expirationDate: Date
    
    func isExpired() -> Bool {
        return self.expirationDate < Date()
    }
}

struct Album {
    let name: String
}

//let networkQueue = DispatchQueue(label: "network")

extension Publisher {
    
    /// The standard delay that a network request would have.
    func networkDelay() -> AnyPublisher<Output, Failure> {
        return self.delay(
            for: .milliseconds(Int.random(in: 100...1_000)),
            scheduler: DispatchQueue.global()
        )
        .eraseToAnyPublisher()
    }

}



