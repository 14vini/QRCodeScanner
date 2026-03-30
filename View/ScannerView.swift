//
//  ScannerView.swift
//  QRCodeScanner
//
//  Created by Vinicius on 7/31/25.
//

import SwiftUI
import AVKit

struct ScannerView: View {
    ///QR Code Properies
    @State private var isScanning: Bool = false
    @State private var session: AVCaptureSession = .init()
    @State private var cameraPermission: Permission = .idle
    ///QR Scanner AV OutPut
    @State private var qrOutput: AVCaptureMetadataOutput = .init()
    ///Error properties
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    @Environment(\.openURL) private var openURL
    @State private var scannedCode: String = ""
    ///Camera QR Output Delegate
    @StateObject private var qrDelegate = QRScannerDelegate()
    
    var body: some View {
        VStack(spacing: 8){
            
            Button{
                
            }label:{
                Image(systemName: "xmark")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .padding(10)
                    .background(.thickMaterial)
                    .clipShape(Circle())
                    
            }
            .frame(maxWidth: .infinity, alignment: .leading)
           
            
            Text("Place the QR code inside the area")
                .font(.title2)
                .foregroundStyle(.primary)
                .padding(.top, 20)
            
            Text("Scanning will start automatically")
                .font(.callout)
                .foregroundStyle(.secondary)
            
            Spacer(minLength: 0)
            
            ///Scanner
            GeometryReader {
                
                let size = $0.size
                
                ZStack{
                    CameraView(frameSize: CGSize( width: size.width, height: size.width), session: $session)
                    /// making a bit smaller
                        .scaleEffect(0.97)
                    
                    ForEach(0...4, id: \.self){ index in
                        let rotation = 90.0 * Double(index)
                        scannerEdgeView
                            .rotationEffect(.degrees(rotation))
                    }
                }
                //Square shape
                .frame(width: size.width, height: size.width)
                //Scanner animation
                .overlay(alignment: .top, content: {
                    Rectangle()
                        .fill(.blue)
                        .frame(height: 2.5)
                        .shadow(color: .black.opacity(0.8), radius: 8, x:0, y: isScanning ? 15 : -15)
                        .offset(y: isScanning ? size.width : 0)
                })
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.horizontal, 45)
                        
            Spacer(minLength: 15)
            
            Button{
                if !session.isRunning && cameraPermission == .approved{
                    reactivateCamera()
                    activatingScannerAnimation()
                }
            }label:{
                Image(systemName: "qrcode.viewfinder")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(.thickMaterial)
                    .clipShape(Circle())
            }
            
            Spacer(minLength: 45)
        }
        .padding(15)
        ///checking Camera Permission when View is Visible
        .onAppear(perform: checkCameraPermission)
        .alert(errorMessage, isPresented: $showError){
            /// showing Settings Button, if permission is denied
            if cameraPermission == .denied{
                Button("settings"){
                    let settingsString = UIApplication.openSettingsURLString
                    if let settingsURL = URL(string: settingsString){
                        /// oppening apps settings, using openURL API
                        openURL(settingsURL)
                    }
                }
                /// Along with Cancel Button
                Button("Cancel", role: .cancel){
                    
                }
            }
        }
        .onChange(of: qrDelegate.scannedCode) { newValue in
            if let code = newValue {
                scannedCode = code
                /// when the code first code is avaliable, imediately the camera.
                session.stopRunning()
                /// stopping Scanner Animation
                deActivatingScannerAnimation()
                /// Cleaning the Data on delegate
                qrDelegate.scannedCode = nil
            }
        }
    }
    
    func reactivateCamera(){
        DispatchQueue.global(qos: .background).async {
            session.startRunning()
        }
    }
    
    /// activationg Scanner Anumation
    func activatingScannerAnimation(){
        /// adding Delay for Each Revesal
        withAnimation(.easeInOut(duration: 0.85).delay(0.1).repeatForever(autoreverses: true)){
            isScanning = true
        }
    }
    
    ///De-activationg Scanner Anumation
    func deActivatingScannerAnimation(){
        /// adding Delay for Each Revesal
        withAnimation(.easeInOut(duration: 0.85)){
            isScanning = false
        }
    }
    
    
    ///checking Camera Permission
    func checkCameraPermission(){
        Task{
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                cameraPermission = .approved
                if session.inputs.isEmpty{
                    /// New Setup
                    setupCamera()
                }else {
                    /// Already have existing one
                    session.startRunning()
                }
                
            case .notDetermined:
                if await AVCaptureDevice.requestAccess(for: .video){
                    ///permission granted
                    cameraPermission = .approved
                } else{
                    ///Permission Denied
                    cameraPermission = .denied
                    /// Presenting Error Message
                    presentError("Please provide Access to Camera for scanning codes")
                }
            case .denied, .restricted:
                cameraPermission = .denied
            default: break
            }
        }
    }
    
    /// Settings Up Camera
    func setupCamera(){
        do{
            /// Finding Back Camera
            guard let device = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .back).devices.first else {
                presentError("UNKNOW DEVICE ERROR")
                return
            }
            /// Camera Input
            let input = try AVCaptureDeviceInput(device: device)
            ///checking where the input and output can be added to the session
            guard session.canAddInput(input), session.canAddOutput(qrOutput) else {
                presentError("UNKNOW INPUT/OUTPUT ERROR")
                return
            }
            
            /// adding Input and Outout
            session.beginConfiguration()
            session.addInput(input)
            session.addOutput(qrOutput)
            /// settings Output config to read QR codes
            qrOutput.metadataObjectTypes = [.qr]
            /// adding delegate to Retrevie the Fetched QR code from Camera
            qrOutput.setMetadataObjectsDelegate(qrDelegate, queue: .main)
            session.commitConfiguration()
            /// note Session must be started on Background thread
            DispatchQueue.global(qos: .background).async {
                session.startRunning()
            }
            activatingScannerAnimation()
            
        } catch{
            presentError(error.localizedDescription)
        }
    }
    
    /// Presenting Error
    func presentError(_ message: String){
        errorMessage = message
        showError.toggle()
    }
    
}

extension ScannerView {
   private var scannerEdgeView: some View {
       RoundedRectangle(cornerRadius: 5, style: .circular)
       //triming to get Scanner like edges
           .trim(from: 0.61, to: 0.64)
           .stroke(Color.blue, style:StrokeStyle( lineWidth: 5, lineCap: .round))
    }
}
#Preview {
    ScannerView()
}
