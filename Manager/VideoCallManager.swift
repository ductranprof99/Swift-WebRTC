//
//  Manager.swift
//  MetaServices
//
//  Created by DucTran on 02/03/2023.
//

import Foundation

enum VideoCallState {
    case beingCalled(incomeSignal: SignalingMessage)
    case empty
    case singleHost(incomeSignal: SignalingMessage)
    case roomHost(hostSignal: [SignalingMessage])
}

public final class VideoCallManager {
    let socket: WebSocketProvider
    var webRTCClient: WebRTCClient
    var tryToConnectWebSocket: Timer!
    var wsStatusMessageBase = "WebSocket: "
    var webRTCStatusMesasgeBase = "WebRTC: "
    
    public var delegate: VideoCallServiceDelegate?
    
    // storeProperty (for room call or single call)
    var storedSignal : VideoCallState = .empty
    
    public var isSocketConnected: Bool {
        get {
            return self.socket.isConnected
        }
    }
    
    public init(iceServer: [String]) {
        if #available(iOS 14, *) {
            socket = NativeWebSocket()
        } else {
            socket = LegacyWebSocket()
        }
        self.webRTCClient = WebRTCClient(iceServer: iceServer)
        socket.delegate = self
        webRTCClient.delegate = self
    }
    
}
