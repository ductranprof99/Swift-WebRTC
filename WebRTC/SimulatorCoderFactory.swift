//
//  SimulatorCoderFactory.swift
//  MetaServices
//
//  Created by DucTran on 02/03/2023.
//

import Foundation
import WebRTC


public class RTCSimulatorVideoDecoderFactory: RTCDefaultVideoDecoderFactory {
    
    public override init() {
        super.init()
    }
    
    public override func supportedCodecs() -> [RTCVideoCodecInfo] {
        var codecs = super.supportedCodecs()
        codecs = codecs.filter{$0.name != "H264"}
        return codecs
    }
}

public class RTCSimluatorVideoEncoderFactory: RTCDefaultVideoEncoderFactory {
    
    public override init() {
        super.init()
    }
    
    public override static func supportedCodecs() -> [RTCVideoCodecInfo] {
        var codecs = super.supportedCodecs()
        codecs = codecs.filter{$0.name != "H264"}
        return codecs
    }
}
