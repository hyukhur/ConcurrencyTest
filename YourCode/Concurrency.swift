//
//  Concurrency.swift


import Foundation

/// Completion of the exection is delayed until `beFinished` is true.
fileprivate class DelayFinishBlockOperation: BlockOperation {
    /// Depends on `beFinished` or `isCancelled` to flag finished
    override var isFinished: Bool {
        return beFinished || isCancelled
    }

    /// To present whether delayed execution is finished.
    var beFinished: Bool = false {
        willSet {
            willChangeValue(for: \.isFinished)
        }
        didSet {
            didChangeValue(for: \.isFinished)
        }
    }

    /// To support `isFinished` KVO with `beFinished` property.
    override class func automaticallyNotifiesObservers(forKey key: String) -> Bool {
        return ["finished", "isFinished"].contains(key) == false
    }
}

let timeoutTimeInterval:TimeInterval = 2.0
let timeoutMessage = "Unable to load message - Time out exceeded"

/// This function should fetch both parts of the message, `fetchMessageOne` and `fetchMessageTwo`.
/// If loading either part of the message takes more than 2 seconds then it should complete with the String
///   "Unable to load message - Time out exceeded".
///
/// This function blocks another execution.
/// If `fetchMessageTwo` doesn't execute the completion handler, it would be freezed.
/// - Parameter completion: The completion handler to execute after the fetch all message is completed.
func loadMessage(completion: @escaping (String) -> Void) {
    let start = Date()
    var message = timeoutMessage
    let timeout = timeoutTimeInterval
    var resultOne = ""
    let operationQueue = OperationQueue()
    let operationOne = DelayFinishBlockOperation()
    let operationTwo = DelayFinishBlockOperation()

    operationOne.addExecutionBlock {
        fetchMessageOne { (messageOne) in
            resultOne = messageOne
            operationOne.beFinished = true
        }
    }
    operationTwo.addExecutionBlock {
        fetchMessageTwo { (messageTwo) in
            let diff = Date().timeIntervalSince(start)
            if diff <= timeout {
                message = "\(resultOne) \(messageTwo)"
            }
            operationTwo.beFinished = true
        }
    }

    operationTwo.addDependency(operationOne)
    operationQueue.addOperation(operationOne)
    operationQueue.addOperation(operationTwo)
    operationQueue.waitUntilAllOperationsAreFinished()
    completion(message)
}
