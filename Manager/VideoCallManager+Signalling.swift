//
//  VideoCallManager+Signalling.swift
//  MetaServices
//
//  Created by DucTran on 02/03/2023.
//

import Foundation
import WebRTC

extension VideoCallManager {
    
    func sendSDP(sessionDescription: RTCSessionDescription){
        var type: MessageType = .ICE
        if sessionDescription.type == .offer {
            type = MessageType.OFFER
        } else if sessionDescription.type == .answer {
            type = MessageType.ANSWER
        }
        
        let sdp = SDP.init(sdp: sessionDescription.sdp)
        let signalingMessage = SignalingMessage.init(type: type.rawValue, sessionDescription: sdp, candidate: nil)
        //        do {
        //            let data = try JSONEncoder().encode(signalingMessage)
        //            let message = String(data: data, encoding: String.Encoding.utf8)!
        //
        //            if self.socket.isConnected {
        //                self.socket.send(data: message.data(using: .utf8)!)
        //            }
        //        }catch{
        //            print(error)
        //        }
        if self.socket.isConnected {
            self.socket.sendString(data: signalingMessage.encodeString)
        }
        
    }
    
    func sendCandidate(iceCandidate: RTCIceCandidate){
        let candidate = Candidate.init(sdp: iceCandidate.sdp, sdpMLineIndex: iceCandidate.sdpMLineIndex, sdpMid: iceCandidate.sdpMid!)
        let signalingMessage = SignalingMessage.init(type: MessageType.ICE.rawValue, sessionDescription: nil, candidate: candidate)
        //        do {
        //            let data = try JSONEncoder().encode(signalingMessage)
        //            let message = String(data: data, encoding: String.Encoding.utf8)!
        //
        //            if self.socket.isConnected {
        //                self.socket.send(data: message.data(using: .utf8)!)
        //            }
        //        }catch{
        //            print(error)
        //        }
        if self.socket.isConnected {
            self.socket.sendString(data: signalingMessage.encodeString)
        }
    }
}
