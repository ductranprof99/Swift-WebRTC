//
//  Message.swift
//  MetaServices
//
//  Created by DucTran on 02/03/2023.
//

import Foundation

public struct SignalingMessage: Codable {
    let type: String
    let sessionDescription: SDP?
    let candidate: Candidate?
    
    var encodeString: String {
        get {
            return "\(type) \(sessionDescription?.sdp ?? candidate?.encodeString ?? "")"
        }
    }
    
    // TODO: init object from string
    static func decodeMessage(from string: String) -> SignalingMessage {
        // Switch case here
        var type = ""
        var sessionDescription: SDP? = nil
        var candidate: Candidate? = nil
        if string.contains("ICE") {
            type = "ICE"
            let components = string.split(separator: " ")
//            print(components)
            let modifiedString = components.dropFirst(1).joined(separator: " ")
//            print(modifiedString)
            candidate = Candidate.decodeMessage(from: modifiedString)
        } else if string.contains("OFFER") {
            type = "OFFER"
            let components = string.split(separator: " ")
            let modifiedString = components.dropFirst(1).joined(separator: " ")
            sessionDescription = SDP.decodeMessage(from: modifiedString)
        } else if string.contains("ANSWER") {
            type = "ANSWER"
            let components = string.split(separator: " ")
            let modifiedString = components.dropFirst(1).joined(separator: " ")
            sessionDescription = SDP.decodeMessage(from: modifiedString)
        }
        return .init(type: type, sessionDescription: sessionDescription, candidate: candidate)
    }
}

public struct SDP: Codable {
    let sdp: String
    
    // TODO: init object from string
    static func decodeMessage(from string: String) -> SDP {
        // Switch case here
        return .init(sdp: string)
    }
}

public struct Candidate: Codable {
    let sdp: String
    let sdpMLineIndex: Int32
    let sdpMid: String
    
    var encodeString: String? {
        get {
            return "\(sdpMid)$\(sdpMLineIndex)$\(sdp)"
        }
    }
    
    // TODO: init object from string
    
    
    static func decodeMessage(from string: String) -> Candidate {
        //
        let part = string.split(separator: "$")
        let sdp = part[2]
        let mid = part[0]
        let mline = Int(part[1]) ?? 0
        return .init(sdp: String(sdp), sdpMLineIndex: Int32(mline), sdpMid: String(mid))
    }
}

enum MessageType: String {
    case OFFER
    case ANSWER
    case ICE
    case CANDIDATE
}
