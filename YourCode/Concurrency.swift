//
//  Concurrency.swift


import Foundation

class DelayFinishBlockOperation: BlockOperation {
    override var isFinished: Bool {
        return beFinished || isCancelled
    }
    var beFinished: Bool = false {
        willSet {
            willChangeValue(for: \.isFinished)
        }
        didSet {
            didChangeValue(for: \.isFinished)
        }
    }
    override class func automaticallyNotifiesObservers(forKey key: String) -> Bool {
        return ["finished", "isFinished"].contains(key) == false
    }
}

let timeoutTimeInterval:TimeInterval = 2.0
let timeoutMessage = "Unable to load message - Time out exceeded"

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
