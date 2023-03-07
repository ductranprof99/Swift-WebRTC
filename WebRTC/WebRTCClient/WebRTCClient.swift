//
//  WebRTCClient.swift
//  MetaServices
//
//  Created by DucTran on 02/03/2023.
//

import UIKit
import WebRTC
import MetaUltility

public protocol WebRTCClientDelegate {
    func didGenerateCandidate(iceCandidate: RTCIceCandidate)
    func didIceConnectionStateChanged(iceConnectionState: RTCIceConnectionState)
    func didOpenDataChannel()
    func didReceiveData(data: Data)
    func didReceiveMessage(message: String)
    func didConnectWebRTC()
    func didDisconnectWebRTC()
    func localVideoChangeSize(size: CGSize)
    func remoteVideoChangeSize(size: CGSize)
}

public class WebRTCClient: NSObject, RTCPeerConnectionDelegate, RTCVideoViewDelegate, RTCDataChannelDelegate {
    
    private var _peerConnectionFactory: RTCPeerConnectionFactory? = nil
    
    var peerConnectionFactory: RTCPeerConnectionFactory! {
        get {
            if _peerConnectionFactory == nil {
                var videoEncoderFactory = RTCDefaultVideoEncoderFactory()
                var videoDecoderFactory = RTCDefaultVideoDecoderFactory()
                
                if TARGET_OS_SIMULATOR != 0 {
                    print("WebRTCClient: setup vp8 codec")
                    videoEncoderFactory = RTCSimluatorVideoEncoderFactory()
                    videoDecoderFactory = RTCSimulatorVideoDecoderFactory()
                }
                _peerConnectionFactory = RTCPeerConnectionFactory(encoderFactory: videoEncoderFactory, decoderFactory: videoDecoderFactory)
            }
            return _peerConnectionFactory!
        }
        set {
            _peerConnectionFactory = newValue
        }
    }
    
    private var _peerConnection: RTCPeerConnection? = nil
    var peerConnection: RTCPeerConnection! {
        get {
            if _peerConnection == nil {
                _peerConnection = setupPeerConnection()
            }
            return _peerConnection!
        }
        set {
            if newValue == nil {
                _peerConnection = newValue
            }
        }
    }
    var videoCapturer: RTCVideoCapturer!
    var localVideoTrack: RTCVideoTrack!
    var localAudioTrack: RTCAudioTrack!
    var localRenderView: RTCMTLVideoView?
    var remoteRenderView: RTCMTLVideoView?
    var remoteStream: RTCMediaStream?
    var dataChannel: RTCDataChannel?
    var remoteDataChannel: RTCDataChannel?
    var channels: (video: Bool, audio: Bool, datachannel: Bool) = (false, false, false)
    var customFrameCapturer: Bool = false
    var cameraDevicePosition: AVCaptureDevice.Position = .front
    
    var delegate: WebRTCClientDelegate?
    var isConnected: Bool = false
    var iceServer: [String]
    
    public init(iceServer: [String]) {
        self.iceServer = iceServer
        super.init()
        print("WebRTCClient: WebRTC Client initialize")
    }
    
    deinit {
        print("WebRTCClient: WebRTC Client Deinit")
        self._peerConnectionFactory = nil
        self._peerConnection = nil
    }
    
    // MARK: - Public functions
    func setup(videoTrack: Bool,
                      audioTrack: Bool,
                      dataChannel: Bool,
                      customFrameCapturer: Bool,
                      localView: UIView,
                      remoteView: UIView){
        print("WebRTCClient: set up")
        self.channels.video = videoTrack
        self.channels.audio = audioTrack
        self.channels.datachannel = dataChannel
        self.customFrameCapturer = customFrameCapturer
        setupLocalTracks()
        setupView(localView: localView, remoteView: remoteView)
        
        if self.channels.video {
            startCaptureLocalVideo(cameraPositon: self.cameraDevicePosition, videoWidth: 640, videoHeight: 640*16/9, videoFps: 30)
            self.localVideoTrack?.add(self.localRenderView!)
        }
    }
}

