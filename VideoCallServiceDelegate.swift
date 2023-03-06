//
//  VideoCallServiceDelegate.swift
//  MetaServices
//
//  Created by DucTran on 02/03/2023.
//

import Foundation

@objc public protocol VideoCallServiceDelegate {
    // Web socket
    @objc optional func webSocketDidConnect()
    
    @objc optional func webSocketDidDisconnect()
    
    @objc optional func webSocket(signalStyle: String)
    
    
    // web rtc
    @objc optional func localVideoChangeSize(size: CGSize)
    /*
    if(isLandScape){
        let ratio = size.width / size.height
        _renderView.frame = CGRect(x: 0, y: 0, width: _parentView.frame.height * ratio, height: _parentView.frame.height)
        _renderView.center.x = _parentView.frame.width/2
    }else{
        let ratio = size.height / size.width
        _renderView.frame = CGRect(x: 0, y: 0, width: _parentView.frame.width, height: _parentView.frame.width * ratio)
        _renderView.center.y = _parentView.frame.height/2
    }
     */
    
    @objc optional func remoteVideoChangeSize(size: CGSize)
    
    @objc optional func candidateDidSend()
    
    @objc optional func didIceConnectionStateChanged(state: String)
    
    @objc optional func didConnectWebRTC()
    
    @objc optional func didDisconnectWebRTC()
    
    @objc optional func didOpenDataChannel()
    
    @objc optional func didReceiveData(data: Data)
    
    @objc optional func didReceiveMessage(message: String)
}
