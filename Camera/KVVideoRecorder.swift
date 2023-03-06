//
//  KVideoRecorder
//
//  Copyright © 2017 Kenan Atmaca. All rights reserved.
//  kenanatmaca.com
//
//

import UIKit
import AVFoundation
import MetaUltility

public enum CaptureMode {
    case photo
    case video
    case stream
}

@available(iOS 11,*)
public class KVideoRecorder: NSObject {
    
    private var captureVideoDevice:AVCaptureDevice!
    private var captureAudioDevice:AVCaptureDevice!
    private var videoDataOutput: AVCaptureVideoDataOutput!
    private var audioDataOutput: AVCaptureAudioDataOutput!
    private var session:AVCaptureSession!
    private var previewLayer:AVCaptureVideoPreviewLayer!
    private var videoOutput:AVCaptureMovieFileOutput!
    private var photoOutput:AVCapturePhotoOutput!
    
    private var zoomGesture:UIPinchGestureRecognizer!
    private var focusGesture:UITapGestureRecognizer!
    private var toggleGesture:UITapGestureRecognizer!
    private var rootView:UIView!
    private var stateZoomScale:CGFloat = 1.0
    private var videoTimer:Timer!
    private var recordTime:Int = 0
    private var captureTyp:CaptureMode!
    
    private let dataOutputQueue = DispatchQueue(label: "VideoDataQueue",
                                                qos: .userInitiated,
                                                attributes: [],
                                                autoreleaseFrequency: .workItem)
    
    private let captureQueue = DispatchQueue(label: "service.camera", qos: .background)
    
    var isAuth:Bool! {
        get {
            return auth()
        }
    }
    
    var isFocus:Bool = false
    var isZoom:Bool = true
    var isToggle:Bool = true
    var videoDelegate:AVCaptureFileOutputRecordingDelegate?
    var photoDelegate:AVCapturePhotoCaptureDelegate?
    var takePhotoImage:UIImage?
    var videoOutputUrl:URL?
    public var delegate: CameraCaptureDelegate?
    
    
    public init(to view:UIView) {
        super.init()
        self.rootView = view
    }
    
    public func setup(_ type:CaptureMode) {
        
        guard isAuth else {
            return
        }
        
        captureTyp = type
        
        session = AVCaptureSession()
        captureAudioDevice = AVCaptureDevice.default(for: AVMediaType.audio)
        captureVideoDevice = AVCaptureDevice.default(for: AVMediaType.video)
        
        do {
            
            try captureVideoDevice?.lockForConfiguration()
            captureVideoDevice?.focusMode = .continuousAutoFocus
            captureVideoDevice?.unlockForConfiguration()
            
        } catch {
            print(error.localizedDescription)
        }
        
        do {
            
            let inputVideo = try AVCaptureDeviceInput(device: captureVideoDevice)
            let inputAudio = try AVCaptureDeviceInput(device: captureAudioDevice)
            session.addInput(inputVideo)
            session.addInput(inputAudio)
            
        } catch {
            print(error.localizedDescription)
        }
        
        switch(type) {
        case .photo:
            photoOutput = AVCapturePhotoOutput()
            session.addOutput(photoOutput)
        case .video:
            videoOutput = AVCaptureMovieFileOutput()
            session.addOutput(videoOutput)
        case .stream:
            videoDataOutput = AVCaptureVideoDataOutput()
            audioDataOutput = AVCaptureAudioDataOutput()
            if session.canAddOutput(videoDataOutput) {
                session.addOutput(videoDataOutput)
                videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
                videoDataOutput.setSampleBufferDelegate(self, queue: dataOutputQueue)
                videoDataOutput.connection(with: .video)?.videoOrientation = .portrait
                videoDataOutput.connection(with: .video)?.automaticallyAdjustsVideoMirroring = false
                videoDataOutput.connection(with: .video)?.isVideoMirrored = true
            } else {
                dLog("Could not add video data output to the session")
                session.commitConfiguration()
            }
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.zPosition = -1
        previewLayer.contentsGravity = .resizeAspectFill
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = rootView.layer.bounds
        rootView.layer.addSublayer(previewLayer)
        
        focusGesture = UITapGestureRecognizer(target: self, action: #selector(focusCam(_:)))
        zoomGesture = UIPinchGestureRecognizer(target: self, action: #selector(zoomCamera(_:)))
        toggleGesture = UITapGestureRecognizer(target: self, action: #selector(toggleCamera))
        toggleGesture.numberOfTapsRequired = 2
        
        if isFocus {rootView.addGestureRecognizer(focusGesture)}
        if isZoom {rootView.addGestureRecognizer(zoomGesture)}
        if isToggle {rootView.addGestureRecognizer(toggleGesture)}
    }
    
    public func startRecording(name:String = "movie") {
        captureQueue.async { [unowned self] in
            self.session.startRunning()
            
            guard self.videoOutput != nil else {
                return
            }
            
            if !self.videoOutput.isRecording {
                if case self.captureTyp = CaptureMode.video {
                    let outputURL = self.generateVideoUrl(name: name)
                    self.videoOutput.startRecording(to: outputURL, recordingDelegate: self)
                    if self.delegate != nil {
                        self.videoTimer = Timer.scheduledTimer(timeInterval: 1,
                                                               target: self,
                                                               selector: #selector(self.setTimerCount),
                                                               userInfo: nil, repeats: true)}
                }
            }
        }
    }
    
    public func stopRecording() {
        captureQueue.async { [unowned self] in
            guard self.videoOutput != nil else {
                return
            }
            
            if self.videoOutput.isRecording {
                self.videoOutput.stopRecording()
                self.videoTimer.invalidate()
            }
        }
    }
    
    
    public func savePicture(image:UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }
    
    public func saveVideo(url:URL) {
        UISaveVideoAtPathToSavedPhotosAlbum(url.path, nil, nil, nil)
    }
    
    @objc private func setTimerCount() {
        
        recordTime += 1
        
        if delegate != nil {
            self.delegate?.timer?(second: recordTime)
        }
    }
    
    public func takePicture() {
        
        guard photoOutput != nil else {
            return
        }
        
        if case captureTyp = CaptureMode.photo {
            let settings = AVCapturePhotoSettings()
            photoOutput.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey:AVVideoCodecType.jpeg])], completionHandler: nil)
            photoOutput.capturePhoto(with: settings, delegate: photoDelegate ?? self as AVCapturePhotoCaptureDelegate)
        }
    }
    
    @objc public func toggleCamera(){
        
        var newCamera:AVCaptureDevice?
        
        func cameraState(_ position:AVCaptureDevice.Position) -> AVCaptureDevice? {
            
            let deviceDescoverySession = AVCaptureDevice.DiscoverySession.init(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera],mediaType: AVMediaType.video,position: AVCaptureDevice.Position.unspecified)
            
            for device in (deviceDescoverySession.devices) {
                if device.position == position {
                    return device
                }
            }
            
            return nil
        }
        
        session?.beginConfiguration()
        
        guard let currentInput = session.inputs.first else {
            print("Wrong down cast K video recorder")
            return
        }
        
        session.removeInput(currentInput)
        
        if captureVideoDevice?.position == AVCaptureDevice.Position.back {
            
            newCamera = cameraState(AVCaptureDevice.Position.front)
            
        } else {
            
            newCamera = cameraState(AVCaptureDevice.Position.back)
        }
        
        captureVideoDevice = newCamera
        
        do {
            
            let deviceInput = try AVCaptureDeviceInput(device: newCamera!)
            
            session?.addInput(deviceInput)
            
        } catch {
            print(error.localizedDescription)
        }
        
        session?.commitConfiguration()
    }
    
    @objc private func focusCam(_ sender:UITapGestureRecognizer) {
        
        let point = sender.location(in: rootView)
        focusObject(point)
    }
    
    private func focusObject(_ point:CGPoint){
        
        if let device = captureVideoDevice {
            
            do {
                
                try device.lockForConfiguration()
                
                if device.isFocusPointOfInterestSupported {
                    
                    device.focusPointOfInterest = point
                }
                
                if device.isExposurePointOfInterestSupported {
                    
                    device.exposurePointOfInterest = point
                    device.exposureMode = .autoExpose
                }
                
                device.unlockForConfiguration()
                
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    @objc private func zoomCamera(_ sender:UIPinchGestureRecognizer){
        
        if let device = captureVideoDevice {
            
            if sender.state == UIGestureRecognizer.State.began { sender.scale = stateZoomScale }
            
            if sender.state == UIGestureRecognizer.State.ended { stateZoomScale = device.videoZoomFactor }
            
            if sender.scale <= 1 { sender.scale = 1 }
            
            else if sender.scale >= 4 { sender.scale = 4 }
            
            do {
                try device.lockForConfiguration()
                device.videoZoomFactor = sender.scale
                device.unlockForConfiguration()
            } catch  {
                print(error.localizedDescription)
            }
        }
    }
    
    @discardableResult
    func delete(name:String) -> Bool {
        
        let bundle = getDir().appendingPathComponent(name.appending(".mov"))
        let manager = FileManager.default
        var result:Bool = false
        
        if self.isExist(name: name) {
            do {
                try manager.removeItem(at: bundle)
                result = true
            } catch {
                print(error.localizedDescription)
                result = false
            }
        }
        
        return result
    }
    
    func removeView() {
        if videoTimer != nil {videoTimer.invalidate()}
        session = nil
        videoOutputUrl = nil
        takePhotoImage = nil
        recordTime = 0
        previewLayer.removeFromSuperlayer()
    }
    
}

@available(iOS 11,*)
extension KVideoRecorder {
    private func generateVideoUrl(name:String) -> URL {
        return getDir().appendingPathComponent(name.appending(".mov"))
    }
    
    
    private func isExist(name:String) -> Bool {
        
        let bundle = getDir().appendingPathComponent(name.appending(".mov"))
        let manager = FileManager.default
        
        return manager.fileExists(atPath: bundle.path) ? true : false
    }
    
    private func getDir() -> URL {
        
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        
        return paths.first!
    }
    
    private func auth() -> Bool {
        
        let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        
        switch (status) {
        case .authorized: return true
        case .denied,.notDetermined,.restricted : return false
        }
    }
}


@available(iOS 11,*)
extension KVideoRecorder: AVCapturePhotoCaptureDelegate {
    
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let imgData = photo.fileDataRepresentation() {
            takePhotoImage = UIImage(data: imgData)
        }
    }
}

@available(iOS 11,*)
extension KVideoRecorder: AVCaptureFileOutputRecordingDelegate {
    public func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if error != nil {
            return
        }
        
        self.videoOutputUrl = outputFileURL
    }
}

@available(iOS 11,*)
extension KVideoRecorder: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let videoDataOutput = videoDataOutput,
              let audioDataOutput = audioDataOutput else { return }
        if connection == videoDataOutput.connection(with: .video) {
            delegate?.captureVideoOutput?(sampleBuffer: sampleBuffer)
        }
        if connection == audioDataOutput.connection(with: .audio) {
            delegate?.captureAudioOutput?(sampleBuffer: sampleBuffer)
        }
    }
    public func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {}
    
}
