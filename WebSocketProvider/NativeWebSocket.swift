//
//  NativeSocketProvider.swift
//

import Foundation
import MetaUltility

@available(iOS 13.0, *)
public class NativeWebSocket: NSObject, WebSocketProvider {
    
    public var delegate: WebSocketProviderDelegate?
    public var isConnected: Bool = false
    private var socket: URLSessionWebSocketTask?
    private lazy var urlSession: URLSession = URLSession(configuration: .default, delegate: self, delegateQueue: nil)

    public override init() {
        super.init()
    }

    public func connect(url: URL) {
        if !isConnected {
            isConnected = true
            let socket = urlSession.webSocketTask(with: url)
            self.socket = socket
            self.socket?.resume()
            readMessage()
        }
    }

    public func send(data: Data) {
        self.socket?.send(.data(data)) { error in
            print(error?.localizedDescription ?? "no error in send data")
        }
    }
    
    public func sendString(data: String) {
        self.socket?.send(.string(data)) { error in
            print(error?.localizedDescription ?? "no error in send string")
        }
    }
    
    private func readMessage()  {
        socket?.receive { result in
            switch result {
            case .failure(let error):
                print("Failed to receive message: \(error)")
            case .success(let message):
                switch message {
                case .string(let text):
                    dLog("Did received string data: -----------")
                    self.delegate?.webSocket(self, didReceivedString: text)
                case .data(let data):
                    dLog("Did received binary data: -----------")
                    self.delegate?.webSocket(self, didReceiveData: data)
                @unknown default:
                    fatalError()
                }
                
                self.readMessage()
            }
        }
    }
    
    public func disconnect() {
        if isConnected {
            self.socket?.cancel(with: .goingAway, reason: nil)
            self.socket = nil
            self.isConnected = false
            self.delegate?.webSocketDidDisconnect(self)
        }
    }
}

@available(iOS 13.0, *)
extension NativeWebSocket: URLSessionWebSocketDelegate, URLSessionDelegate  {
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        self.delegate?.webSocketDidConnect(self)
    }
    
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
    }
}
