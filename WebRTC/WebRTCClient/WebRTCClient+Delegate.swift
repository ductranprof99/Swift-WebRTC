//
//  WebRTCClient+Delegates.swift
//  MetaServices
//
//  Created by DucTran on 07/03/2023.
//

import Foundation
import WebRTC


// MARK: - PeerConnection Delegeates
extension WebRTCClient {
    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        var state = ""
        if stateChanged == .stable{
            state = "stable"
        }
        
        if stateChanged == .closed{
            state = "closed"
        }
        
        print("WebRTCClient: signaling state changed: " + state)
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        
        switch newState {
        case .connected, .completed:
            if !self.isConnected {
                self.onConnected()
            }
        default:
            if self.isConnected{
                self.onDisConnected()
            }
        }
        
        DispatchQueue.main.async {
            self.delegate?.didIceConnectionStateChanged(iceConnectionState: newState)
        }
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        print("WebRTCClient: did add stream")
        self.remoteStream = stream
        
        if let track = stream.videoTracks.first {
            print("WebRTCClient: video track found")
            track.add(remoteRenderView!)
        }
        
        if let audioTrack = stream.audioTracks.first{
            print("WebRTCClient: audio track found")
            audioTrack.source.volume = 8
        }
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        print("WebRTCClient: -- did generate candidate --")
        self.delegate?.didGenerateCandidate(iceCandidate: candidate)
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        print("WebRTCClient: --- did remove stream ---")
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        self.remoteDataChannel = dataChannel
        self.delegate?.didOpenDataChannel()
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {}
    
    public func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {}
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {}
}

// MARK: - RTCVideoView Delegate
extension WebRTCClient{
    public func videoView(_ videoView: RTCVideoRenderer, didChangeVideoSize size: CGSize) {
        if videoView.isEqual(localRenderView){
            self.delegate?.localVideoChangeSize(size: size)
        }
        
        if videoView.isEqual(remoteRenderView!){
            self.delegate?.remoteVideoChangeSize(size: size)
        }
    }
}

// MARK: - RTCDataChannelDelegate
extension WebRTCClient {
    public func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        DispatchQueue.main.async {
            if buffer.isBinary {
                self.delegate?.didReceiveData(data: buffer.data)
            }else {
                self.delegate?.didReceiveMessage(message: String(data: buffer.data, encoding: String.Encoding.utf8)!)
            }
        }
    }
    
    public func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
        print("WebRTCClient: data channel did change state")
        switch dataChannel.readyState {
        case .closed:
            print("WebRTCClient: closed")
        case .closing:
            print("WebRTCClient: closing")
        case .connecting:
            print("WebRTCClient: connecting")
        case .open:
            print("WebRTCClient: open")
        @unknown default:
            fatalError("channel change state but not handle")
        }
    }
}
