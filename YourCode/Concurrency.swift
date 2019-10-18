//
//  Concurrency.swift


import Foundation

let timeoutTimeInterval: Int = 2
let timeoutMessage = "Unable to load message - Time out exceeded"

/// This function should fetch both parts of the message, `fetchMessageOne` and `fetchMessageTwo`.
/// If loading either part of the message takes more than 2 seconds then it should complete with the String
///   "Unable to load message - Time out exceeded".
///
/// This function blocks another execution.
/// - Parameter completion: The completion handler to execute after the fetch all message is completed.
func loadMessage(completion: @escaping (String) -> Void) {
    let group = DispatchGroup()
    var firstMessage = ""
    var secondMessage = ""
    group.enter()
    fetchMessageOne { (messageOne) in
        firstMessage = messageOne
        group.leave()
    }
    group.enter()
    fetchMessageTwo { (messageTwo) in
        secondMessage = messageTwo
        group.leave()
    }

    switch group.wait(timeout: DispatchTime.now() + DispatchTimeInterval.seconds(timeoutTimeInterval) ) {
    case .success:
        completion("\(firstMessage) \(secondMessage)")
    case .timedOut:
        completion(timeoutMessage)
    }
}
