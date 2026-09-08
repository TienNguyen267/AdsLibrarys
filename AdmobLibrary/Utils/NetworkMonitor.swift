//
//  NetworkMonitor.swift
//  67 - Tap Challenge IOS
//
//  Created by Tien Nguyen on 15/10/25.
//

import Foundation
import Network
import Combine

class NetworkMonitor: ObservableObject {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    @Published var isConnected: Bool = false
    
    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }
    
    deinit {
        monitor.cancel()
    }
    
    static func checkConnection() -> Bool {
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "NetworkCheck")
        var isConnected = false
        
        monitor.pathUpdateHandler = { path in
            isConnected = path.status == .satisfied
        }
        
        monitor.start(queue: queue)
        // Give it a moment to check
        Thread.sleep(forTimeInterval: 0.1)
        monitor.cancel()
        
        return isConnected
    }
}

