//
//  QRScannerDelegate.swift
//  QRCodeScanner
//
//  Created by Vinicius on 8/4/25.
//

import SwiftUI
import AVKit

class QRScannerDelegate: NSObject, ObservableObject, AVCaptureMetadataOutputObjectsDelegate {
    @Published var scannedCode: String?

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metaObject = metadataObjects.first,
           let readableObject = metaObject as? AVMetadataMachineReadableCodeObject,
           let code = readableObject.stringValue {
            print(code)
            self.scannedCode = code
        }
    }
}
