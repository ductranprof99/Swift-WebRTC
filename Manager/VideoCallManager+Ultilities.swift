//
//  VideoCallManager+Ultility.swift
//  MetaServices
//
//  Created by DucTran on 02/03/2023.
//

import Foundation
import WebRTC

typealias VideoCallReport = (sender: RTCStatisticsReport?,
                             receiver: RTCStatisticsReport?)

extension VideoCallManager {
    
    public func connect(host: String,
                        port: String,
                        part: String?,
                        onCompleted: @escaping ((Bool) -> Void)) {
        guard let url = URL(string: "ws://\(host):\(port)" + (part ?? "")) else {
            print("Cannot connect, url invalid")
            return
        }
        var isCompleted = false
        tryToConnectWebSocket = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [weak self] (timer) in
            guard let self = self else { return }
            if self.socket.isConnected {
                if !isCompleted {
                    isCompleted = true
                    onCompleted(self.socket.isConnected)
                }
                return
            }
            
            self.socket.connect(url: url)
        })
    }
    
    public func startSession(){
        if !webRTCClient.isConnected {
            webRTCClient.connect(onSuccess: { (sdp: RTCSessionDescription) -> Void in
                self.sendSDP(sessionDescription: sdp)
            })
        }
    }
    
    public func answerCall() {
        switch self.storedSignal {
            
        case .beingCalled(incomeSignal: let incomeSignal):
            webRTCClient.receiveOffer(offerSDP: RTCSessionDescription(type: .offer, sdp: (incomeSignal.sessionDescription?.sdp)!), onCreateAnswer: {(answerSDP: RTCSessionDescription) -> Void in
                self.sendSDP(sessionDescription: answerSDP)
            })
        case .empty, .singleHost:
            break
        case .roomHost:
            break
        }
    }
    
    public func hangupButtonTapped(){
        if webRTCClient.isConnected {
            webRTCClient.disconnect()
        }
    }
    
    public func sendMessageButtonTapped(text: String){
        webRTCClient.sendMessge(message: text)
    }
    
    public func switchCamera() {
        webRTCClient.switchCameraPosition()
    }
    
    public func setUp(videoTrack: Bool,
                      audioTrack: Bool,
                      dataChannel: Bool,
                      localView: UIView,
                      remoteView: UIView){
        webRTCClient.setup(videoTrack: videoTrack,
                           audioTrack: audioTrack,
                           dataChannel: dataChannel,
                           customFrameCapturer: true,
                           localView: localView,
                           remoteView: remoteView)
    }
    
    public func captureCurrentFrame(sampleBuffer: CMSampleBuffer){
        webRTCClient.captureCurrentFrame(sampleBuffer: sampleBuffer)
    }
    
    public func captureCurrentFrame(sampleBuffer: CVPixelBuffer){
        webRTCClient.captureCurrentFrame(sampleBuffer: sampleBuffer)
    }
}
