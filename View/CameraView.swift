//
//  CameraView.swift
//  QRCodeScanner
//
//  Created by Vinicius on 7/31/25.
//

import SwiftUI
import AVKit

///camera View using AVCaptuirePreviewLayer
struct CameraView: UIViewRepresentable {
    
    var frameSize: CGSize
    ///Camera Session
    @Binding var session: AVCaptureSession
    
    func makeUIView(context: Context) -> some UIView {
        ///Defining Camera Frame
        let view = UIView(frame: CGRect(origin: .zero, size: frameSize))
        view.backgroundColor = .clear
        
        let cameraLayer = AVCaptureVideoPreviewLayer(session: session)
        cameraLayer.frame = .init(origin: .zero, size: frameSize)
        cameraLayer.videoGravity = .resizeAspectFill
        cameraLayer.masksToBounds = true
        view.layer.addSublayer(cameraLayer)
        
        return view
    }
    
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        
    }
}


