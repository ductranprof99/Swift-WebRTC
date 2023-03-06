//
//  LegacyWebSocket.swift
//  MetaServices
//
//  Created by DucTran on 01/03/2023.
//

import Foundation
import MetaUltility
import Starscream

public final class LegacyWebSocket: WebSocketProvider {
    public var isConnected: Bool = false
    public var delegate: WebSocketProviderDelegate?
    private var socket: WebSocket? = nil
    
    
    public func connect(url: URL) {
        if self.socket == nil {
            self.socket = WebSocket(request: URLRequest(url: url))
            self.socket?.delegate = self
            self.socket?.connect()
        }
    }
    
    public func send(data: Data) {
        self.socket?.write(data: data)
    }
    
    public func sendString(data: String) {
        self.socket?.write(string: data)
    }
    
    public func disconnect() {
        guard let socket = socket else { return }
        socket.forceDisconnect()
        self.socket = nil
    }
}

extension LegacyWebSocket: WebSocketDelegate {
    
    public func didReceive(event: Starscream.WebSocketEvent, client: Starscream.WebSocket) {
        switch event {
        case .connected:
            isConnected = true
            self.delegate?.webSocketDidConnect(self)
        case .disconnected:
            isConnected = false
            self.delegate?.webSocketDidDisconnect(self)
        case .text(let textString):
            dLog("Did received string data: -----------")
            self.delegate?.webSocket(self, didReceivedString: textString)
        case .binary(let data):
            dLog("Did received binary data: -----------")
            self.delegate?.webSocket(self, didReceiveData: data)
        default:
            break
        }
    }
}
