import Foundation
public struct BVNetworkLaunchOptions {
    
    
}

public class BVNetworking {
    // getter is public setter is private
    static public private(set) var shared = BVNetworking()
    
    public private(set) var launchOptions: BVNetworkLaunchOptions?
    
    private init() {
        
    }
    
    public func bootstrap(with launchOptions: BVNetworkLaunchOptions?) {
        self.launchOptions = launchOptions
    }
            
}

public class ServiceInvoker<Response: Codable> {
    var urlString: String = ""
    var completion: ((Result<Response, BVNetworkingError>) -> Void)?
    
    public init(urlString: String) {
        self.urlString = urlString
    }
    
    public func getData(completion: @escaping ((Result<Response, BVNetworkingError>) -> Void)) {
        self.completion = completion
        guard let url = URL(string: urlString) else {
            completion(.failure(BVNetworkingError.urlCreationFailure))
            return
        }
        
        let urlRequest = URLRequest(url: url)
        let task = URLSession.shared.dataTask(with: urlRequest) { [weak self] data, response, error in
            self?.parseData(data: data, response: response, error: error)
        }
        task.resume()
    }
    
    func parseData(data: Data?, response: URLResponse?, error: Error?) {
        if error != nil {
            // Send error
            completion?(.failure(BVNetworkingError.emptyURL))
        } else if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
            // Parse the data
            if let data = data {
                do {
                     let parsedJson = try JSONDecoder().decode(Response.self, from: data)
                     completion?(.success(parsedJson))
                } catch {
                    completion?(.failure(BVNetworkingError.errorParsingJson))
                }
            } else {
                completion?(.failure(BVNetworkingError.emptyData))
            }
        } else {
            completion?(.failure(BVNetworkingError.emptyURL))
        }
    }
}


public enum BVNetworkingError: Error {
    case emptyURL
    case urlCreationFailure
    case urlRequestCreationFailure
    case errorParsingJson
    case emptyData
}

