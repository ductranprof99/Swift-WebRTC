//
//  CameraDelegate.swift
//  UIComponents
//
//  Created by DucTran on 17/02/2023.
//

import Foundation
import UIKit
import AVFoundation


enum CameraError: Error {
    case captureDeviceNotFound
    case configurationFailed
    case imageCreationFailed
}

@objc public
protocol CameraCaptureDelegate {
    @objc optional func captureVideoOutput(sampleBuffer: CMSampleBuffer)
    @objc optional func captureAudioOutput(sampleBuffer: CMSampleBuffer)
    @objc optional func captureImageOutput(sampleBuffer: CMSampleBuffer)
    @objc optional func timer(second:Int)
}
