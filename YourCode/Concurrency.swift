//
//  Concurrency.swift


import Foundation

/// It gathers messages from Fetcher functions and concats these.
struct MessageComposer {
    typealias CompletionHandler = (String) -> Void
    typealias Fetcher = (@escaping CompletionHandler) -> ()

    // Functions to able to fetch a message with a completion handler.
    var fetchers: [Fetcher]

    static let timeoutMessage = "Unable to load message - Time out exceeded"

    /// Sync function to load messages from fetch functions.
    ///
    /// - Parameter timeout: Timeout to wait for the result.
    /// - Returns: Composed messages from fetch functions or the timeout message after timeout.
    func fetch(timeout: DispatchTimeInterval = .seconds(2)) -> String {
        let group: DispatchGroup = DispatchGroup()
        var results: [String] = Array(repeating: "", count: fetchers.count)

        for fetcher in fetchers.enumerated() {
            group.enter()
            fetcher.element() { message in
                results[fetcher.offset] = message
                group.leave()
            }
        }
        switch group.wait(timeout: DispatchTime.now() + timeout) {
        case .success:
            return results.joined(separator: " ")
        case .timedOut:
            return MessageComposer.timeoutMessage
        }
    }

    /// Async function to load messages from fetch functions.
    ///
    /// This function blocks another execution.
    /// - Parameters:
    ///   - timeout: Timeout to wait for the result.
    ///   - completion: The completion handler to execute after the fetch all messages is completed with Composed messages from fetch functions or the timeout message after timeout.
    func load(timeout: DispatchTimeInterval = .seconds(2), completion: @escaping (String) -> Void) {
        let message = self.fetch(timeout: timeout)
        completion(message)
    }
}

/// This function should fetch both parts of the message, `fetchMessageOne` and `fetchMessageTwo`.
/// If loading either part of the message takes more than 2 seconds then it should complete with the String
///   "Unable to load message - Time out exceeded".
///
/// This function blocks another execution.
/// - Parameter completion: The completion handler to execute after the fetch all messages is completed.
func loadMessage(completion: @escaping (String) -> Void) {
    MessageComposer(fetchers: [fetchMessageOne(completion:), fetchMessageTwo(completion:)]).load(completion: completion)
}
