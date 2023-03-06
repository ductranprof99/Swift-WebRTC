//
//  File.swift
//

import Foundation

public protocol WebSocketProvider: AnyObject {
    var isConnected: Bool { get set }
    var delegate: WebSocketProviderDelegate? { get set }
    func connect(url: URL)
    func send(data: Data)
    func sendString(data: String)
    func disconnect()
}

public protocol WebSocketProviderDelegate: AnyObject {
    func webSocketDidConnect(_ webSocket: WebSocketProvider)
    func webSocketDidDisconnect(_ webSocket: WebSocketProvider)
    func webSocket(_ webSocket: WebSocketProvider, didReceiveData data: Data)
    func webSocket(_ webSocket: WebSocketProvider, didReceivedString string: String)
}
