//
//  VideoCallManagerDelegate.swift
//  MetaServices
//
//  Created by DucTran on 02/03/2023.
//

import Foundation
import WebRTC

extension VideoCallManager: WebRTCClientDelegate {
    public func localVideoChangeSize(size: CGSize) {
        self.delegate?.localVideoChangeSize?(size: size)
    }
    
    public func remoteVideoChangeSize(size: CGSize) {
        self.delegate?.remoteVideoChangeSize?(size: size)
    }
    
    public func didGenerateCandidate(iceCandidate: RTCIceCandidate) {
        self.sendCandidate(iceCandidate: iceCandidate)
        self.delegate?.candidateDidSend?()
    }
    
    public func didIceConnectionStateChanged(iceConnectionState: RTCIceConnectionState) {
        var state = ""
        
        switch iceConnectionState {
        case .checking:
            state = "checking..."
        case .closed:
            state = "closed"
        case .completed:
            state = "completed"
        case .connected:
            state = "connected"
        case .count:
            state = "count..."
        case .disconnected:
            state = "disconnected"
        case .failed:
            state = "failed"
        case .new:
            state = "new..."
        @unknown default:
            fatalError("Unhandle state of ice connection state in video call manager  + delegate")
        }
        self.delegate?.didIceConnectionStateChanged?(state: state)
    }
    
    public func didConnectWebRTC() {
        // MARK: Disconnect websocket
        self.socket.disconnect()
        self.delegate?.didConnectWebRTC?()
    }
    
    public func didDisconnectWebRTC() {
        // MARK: Pass event to delegate
        self.delegate?.didDisconnectWebRTC?()
    }
    
    public func didOpenDataChannel() {
        self.delegate?.didOpenDataChannel?()
    }
    
    public func didReceiveData(data: Data) {
        // TODO: call delegate to display data or something (not video)
        print("Data received")
        self.delegate?.didReceiveData?(data: data)
    }
    
    public func didReceiveMessage(message: String) {
        // TODO: call delegate to display data or something (not video)
        print("Data received")
        self.delegate?.didReceiveMessage?(message: message)
    }
}


extension VideoCallManager: WebSocketProviderDelegate {
    public func webSocketDidConnect(_ webSocket: WebSocketProvider) {
        print("-- websocket did connect --")
        self.delegate?.webSocketDidConnect?()
    }
    
    public func webSocketDidDisconnect(_ webSocket: WebSocketProvider) {
        print("-- websocket did disconnect --")
        self.delegate?.webSocketDidDisconnect?()
    }
    
    public func webSocket(_ webSocket: WebSocketProvider, didReceiveData data: Data) {
        //TODO: Decode message here
        do{
            let signalingMessage = try JSONDecoder().decode(SignalingMessage.self, from: data)
            
            if signalingMessage.type == MessageType.OFFER.rawValue {
                self.storedSignal = .beingCalled(incomeSignal: signalingMessage)
            }else if signalingMessage.type == MessageType.ANSWER.rawValue {
                self.storedSignal = .singleHost(incomeSignal: signalingMessage)
                webRTCClient.receiveAnswer(answerSDP: RTCSessionDescription(type: .answer, sdp: (signalingMessage.sessionDescription?.sdp)!))
            }else if signalingMessage.type == MessageType.ICE.rawValue {
                let candidate = signalingMessage.candidate!
                webRTCClient.receiveCandidate(candidate: RTCIceCandidate(sdp: candidate.sdp, sdpMLineIndex: candidate.sdpMLineIndex, sdpMid: candidate.sdpMid))
            }
            self.delegate?.webSocket?(signalStyle: signalingMessage.type)
        }catch{
            print(error)
        }
    }
    
    public func webSocket(_ webSocket: WebSocketProvider, didReceivedString string: String) {
        // TODO: Re encoding data string to format
        let signalingMessage = SignalingMessage.decodeMessage(from: string)
        if signalingMessage.type == MessageType.OFFER.rawValue {
            self.storedSignal = .beingCalled(incomeSignal: signalingMessage)
        }else if signalingMessage.type == MessageType.ANSWER.rawValue {
            self.storedSignal = .singleHost(incomeSignal: signalingMessage)
            webRTCClient.receiveAnswer(answerSDP: RTCSessionDescription(type: .answer, sdp: (signalingMessage.sessionDescription?.sdp)!))
        }else if signalingMessage.type == MessageType.ICE.rawValue {
            let candidate = signalingMessage.candidate!
            webRTCClient.receiveCandidate(candidate: RTCIceCandidate(sdp: candidate.sdp, sdpMLineIndex: candidate.sdpMLineIndex, sdpMid: candidate.sdpMid))
        }
        self.delegate?.webSocket?(signalStyle: signalingMessage.type)
    }
}
