//
//  Concurrency.swift


import Foundation

func loadMessage(completion: @escaping (String) -> Void) {
    
    fetchMessageOne { (messageOne) in
    }
    
    fetchMessageTwo { (messageTwo) in
    }
    completion("Good morning!")
}
