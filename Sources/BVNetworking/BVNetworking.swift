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
        /*
         URLSession.shared.dataTask(with:), the task is executed on a background thread. This is because URLSession is designed to perform network operations asynchronously in the background, so as not to block the main thread and make the user interface unresponsive.
         
         However, it's important to note that the completion handler of the URLSessionDataTask is called on the thread that created the task, which is usually the main thread. This is because the completion handler typically updates the user interface or performs some other operation that should happen on the main thread.
         
         To avoid blocking the main thread while the network request is being performed, it's recommended to create the URLSessionDataTask on a background thread, for example by using Grand Central Dispatch (GCD) or by using an asynchronous method like DispatchQueue.global().async. This will ensure that the task is executed on a background thread, and that the main thread remains responsive to user input.
         
         */
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



public class SharedNetworkQueues: OperationQueue {
    public static let shared = SharedNetworkQueues()
}

public class DownloadAndParseJSONOperation<Response: Codable>: Operation {
    
    let serviceInvoker: ServiceInvoker<Response>
    let completion: ((Result<Response, BVNetworkingError>) -> Void)?
    
    public init(serviceInvoker: ServiceInvoker<Response>, completion: ((Result<Response, BVNetworkingError>) -> Void)?) {
        self.serviceInvoker = serviceInvoker
        self.completion = completion
    }
    
    public override func main() {
        guard isCancelled == false else {
            print("operation cancelled")
            return
        }
        
        print("executing myoperation")
        print("Current thread: \(Thread.current.name ?? "unknown")")
        self.serviceInvoker.getData { result in
            self.completion?(result)
            print("Current thread: \(Thread.current.name ?? "unknown")")
        }
    }
    
    public override func cancel() {
        super.cancel()
        
        // Perform any additional cleanup or notification
        print("MyOperation was cancelled via cancel() method \(isCancelled)")
    }
    
    
}
