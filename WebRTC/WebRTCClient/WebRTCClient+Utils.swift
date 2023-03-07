//
//  WebRTCClient+Utils.swift
//  MetaServices
//
//  Created by DucTran on 07/03/2023.
//

import Foundation
import WebRTC

extension WebRTCClient {
    func switchCameraPosition(){
        if let capturer = self.videoCapturer as? RTCCameraVideoCapturer {
            capturer.stopCapture {
                let position = (self.cameraDevicePosition == .front) ? AVCaptureDevice.Position.back : AVCaptureDevice.Position.front
                self.cameraDevicePosition = position
                self.startCaptureLocalVideo(cameraPositon: position, videoWidth: 640, videoHeight: 640*16/9, videoFps: 30)
            }
        }
    }
    
    // MARK: Connect
    func connect(onSuccess: @escaping (RTCSessionDescription) -> Void){
        self.peerConnection.delegate = self
        
        if self.channels.video {
            self.peerConnection.add(localVideoTrack, streamIds: ["stream0"])
        }
        if self.channels.audio {
            self.peerConnection.add(localAudioTrack, streamIds: ["stream0"])
        }
        if self.channels.datachannel {
            self.dataChannel = self.setupDataChannel()
            self.dataChannel?.delegate = self
        }
        makeOffer(onSuccess: onSuccess)
    }
    
    // MARK: HangUp
    func disconnect(){
        self.peerConnection.close()
    }
    
    // MARK: Signaling Event
    func receiveOffer(offerSDP: RTCSessionDescription, onCreateAnswer: @escaping (RTCSessionDescription) -> Void){
        self.peerConnection.delegate = self
        if self.channels.video {
            self.peerConnection.add(localVideoTrack, streamIds: ["stream-0"])
        }
        if self.channels.audio {
            self.peerConnection.add(localAudioTrack, streamIds: ["stream-0"])
        }
        if self.channels.datachannel {
            self.dataChannel = self.setupDataChannel()
            self.dataChannel?.delegate = self
        }
        
        
        print("WebRTCClient: set remote description")
        self.peerConnection.setRemoteDescription(offerSDP) { (err) in
            if let error = err {
                print("WebRTCClient: failed to set remote offer SDP")
                print(error)
                return
            }
            
            print("WebRTCClient: succeed to set remote offer SDP")
            self.makeAnswer(onCreateAnswer: onCreateAnswer)
        }
    }
    
    func receiveAnswer(answerSDP: RTCSessionDescription){
        self.peerConnection.setRemoteDescription(answerSDP) { (err) in
            if let error = err {
                print("WebRTCClient: failed to set remote answer SDP")
                print(error)
                return
            }
        }
    }
    
    func receiveCandidate(candidate: RTCIceCandidate){
        self.peerConnection.add(candidate)
    }
    
    // MARK: DataChannel Event
    func sendMessge(message: String){
        if let _dataChannel = self.remoteDataChannel {
            if _dataChannel.readyState == .open {
                let buffer = RTCDataBuffer(data: message.data(using: String.Encoding.utf8)!, isBinary: false)
                _dataChannel.sendData(buffer)
            }else {
                print("WebRTCClient: data channel is not ready state")
            }
        }else{
            print("WebRTCClient: no data channel")
        }
    }
    
    func sendData(data: Data){
        if let _dataChannel = self.remoteDataChannel {
            if _dataChannel.readyState == .open {
                let buffer = RTCDataBuffer(data: data, isBinary: true)
                _dataChannel.sendData(buffer)
            }
        }
    }
    
    func captureCurrentFrame(sampleBuffer: CMSampleBuffer){
        if let capturer = self.videoCapturer as? RTCCustomFrameCapturer {
            capturer.capture(sampleBuffer)
        }
    }
    
    func captureCurrentFrame(sampleBuffer: CVPixelBuffer){
        if let capturer = self.videoCapturer as? RTCCustomFrameCapturer {
            capturer.capture(sampleBuffer)
        }
    }
    
    func getReport(onCompleted: @escaping (VideoCallReport) -> Void) {
        var report = VideoCallReport(sender: nil, receiver: nil)
        guard let firstSender = peerConnection.senders.first else { return }
        peerConnection.statistics(for: firstSender) {
            report.sender = $0
        }
        peerConnection.statistics {
            report.receiver = $0
        }
        onCompleted(report)
    }
}

extension WebRTCClient {
    
    func setupView(localView: UIView, remoteView: UIView){
        // local
        localRenderView = RTCMTLVideoView(frame: localView.frame)
        localRenderView?.transform = CGAffineTransformMakeScale(-1, 1)
        localRenderView!.delegate = self
        localRenderView?.embedView(into: localView)
        // remote
        remoteRenderView = RTCMTLVideoView(frame: remoteView.frame)
        remoteRenderView?.delegate = self
        remoteRenderView?.embedView(into: remoteView)
        
    }
    
    //MARK: - Local Media
    func setupLocalTracks(){
        if self.channels.video == true {
            self.localVideoTrack = createVideoTrack()
        }
        if self.channels.audio == true {
            self.localAudioTrack = createAudioTrack()
        }
    }
    
    func createAudioTrack() -> RTCAudioTrack {
        let audioConstrains = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        let audioSource = self.peerConnectionFactory.audioSource(with: audioConstrains)
        let audioTrack = self.peerConnectionFactory.audioTrack(with: audioSource, trackId: "ARDAMSv0")
        return audioTrack
    }
    
    func createVideoTrack() -> RTCVideoTrack {
        let videoSource = self.peerConnectionFactory.videoSource()
        
        if self.customFrameCapturer {
            self.videoCapturer = RTCCustomFrameCapturer(delegate: videoSource)
        }else if TARGET_OS_SIMULATOR != 0 {
            print("WebRTCClient: now runnnig on simulator...")
            self.videoCapturer = RTCFileVideoCapturer(delegate: videoSource)
        }
        else {
            self.videoCapturer = RTCCameraVideoCapturer(delegate: videoSource)
        }
        let videoTrack = self.peerConnectionFactory.videoTrack(with: videoSource, trackId: "ARDAMSv0")
        return videoTrack
    }
    
    // Start capturing
    func startCaptureLocalVideo(cameraPositon: AVCaptureDevice.Position, videoWidth: Int, videoHeight: Int?, videoFps: Int) {
        if let capturer = self.videoCapturer as? RTCCameraVideoCapturer {
            var targetDevice: AVCaptureDevice?
            var targetFormat: AVCaptureDevice.Format?
            
            // find target device
            let devicies = RTCCameraVideoCapturer.captureDevices()
            devicies.forEach { (device) in
                if device.position ==  cameraPositon{
                    targetDevice = device
                }
            }
            
            // find target format
            let formats = RTCCameraVideoCapturer.supportedFormats(for: targetDevice!)
            formats.forEach { (format) in
                for _ in format.videoSupportedFrameRateRanges {
                    let description = format.formatDescription as CMFormatDescription
                    let dimensions = CMVideoFormatDescriptionGetDimensions(description)
                    
                    if dimensions.width == videoWidth && dimensions.height == videoHeight ?? 0{
                        targetFormat = format
                    } else if dimensions.width == videoWidth {
                        targetFormat = format
                    }
                }
            }
            
            capturer.startCapture(with: targetDevice!,
                                  format: targetFormat!,
                                  fps: videoFps)
        } else if let capturer = self.videoCapturer as? RTCFileVideoCapturer{
            print("WebRTCClient: setup file video capturer")
            if let _ = Bundle.main.path( forResource: "sample.mp4", ofType: nil ) {
                capturer.startCapturing(fromFileNamed: "sample.mp4") { (err) in
                    print(err)
                }
            }else{
                print("WebRTCClient: file did not found")
            }
        }
    }
    
    // Local Data
    func setupDataChannel() -> RTCDataChannel{
        let dataChannelConfig = RTCDataChannelConfiguration()
        dataChannelConfig.channelId = 0
        
        let _dataChannel = self.peerConnection.dataChannel(forLabel: "dataChannel", configuration: dataChannelConfig)
        return _dataChannel!
    }
}

// MARK: - Connection setup
extension WebRTCClient {
    
    func setupPeerConnection() -> RTCPeerConnection{
        let config = RTCConfiguration()
        config.sdpSemantics = RTCSdpSemantics.unifiedPlan
        config.certificate = RTCCertificate.generate(withParams: ["expires": NSNumber(value: 100000),
                                                                  "name": "RSASSA-PKCS1-v1_5"])
        config.iceServers = [RTCIceServer(urlStrings: self.iceServer)]
        let mediaConstraints = RTCMediaConstraints.init(mandatoryConstraints: nil, optionalConstraints: nil)
        let pc = self.peerConnectionFactory.peerConnection(with: config, constraints: mediaConstraints, delegate: nil)
        return pc
    }
    
    // MARK: Signaling Offer/Answer
    func makeOffer(onSuccess: @escaping (RTCSessionDescription) -> Void) {
        self.peerConnection.offer(for: RTCMediaConstraints.init(mandatoryConstraints: nil, optionalConstraints: nil)) { (sdp, err) in
            if let error = err {
                print("WebRTCClient: error with make offer")
                print(error)
                return
            }
            
            if let offerSDP = sdp {
                print("WebRTCClient: make offer, created local sdp")
                self.peerConnection.setLocalDescription(offerSDP, completionHandler: { (err) in
                    if let error = err {
                        print("WebRTCClient: error with set local offer sdp")
                        print(error)
                        return
                    }
                    print("WebRTCClient: succeed to set local offer SDP")
                    onSuccess(offerSDP)
                })
            }
        }
    }
    
    func makeAnswer(onCreateAnswer: @escaping (RTCSessionDescription) -> Void){
        self.peerConnection.answer(for: RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil), completionHandler: { (answerSessionDescription, err) in
            if let error = err {
                print("WebRTCClient: failed to create local answer SDP")
                print(error)
                return
            }
            
            print("WebRTCClient: succeed to create local answer SDP")
            if let answerSDP = answerSessionDescription{
                self.peerConnection.setLocalDescription( answerSDP, completionHandler: { (err) in
                    if let error = err {
                        print("WebRTCClient: failed to set local ansewr SDP")
                        print(error)
                        return
                    }
                    
                    print("WebRTCClient: succeed to set local answer SDP")
                    onCreateAnswer(answerSDP)
                })
            }
        })
    }
    
    // MARK: - Connection Events
    func onConnected(){
        self.isConnected = true
        
        DispatchQueue.main.async {
            self.remoteRenderView?.isHidden = false
            self.delegate?.didConnectWebRTC()
        }
    }
    
    func onDisConnected(){
        self.isConnected = false
        
        DispatchQueue.main.async {
            print("WebRTCClient: --- on dis connected ---")
            self.peerConnection.close()
            self.peerConnection = nil
            self.dataChannel = nil
            self.delegate?.didDisconnectWebRTC()
        }
    }
}


