//
//  Extension.swift
//  Dice Random
//
//  Created by Tien Nguyen on 23/10/25.
//

import SwiftUI
import AVFoundation
import UIKit

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")
        
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Back Button Handler
struct BackButtonHandler: UIViewControllerRepresentable {
    let onBackPressed: () -> Void
    
    func makeUIViewController(context: Context) -> BackButtonViewController {
        let controller = BackButtonViewController()
        controller.onBackPressed = onBackPressed
        return controller
    }
    
    func updateUIViewController(_ uiViewController: BackButtonViewController, context: Context) {
        uiViewController.onBackPressed = onBackPressed
    }
}

class BackButtonViewController: UIViewController {
    var onBackPressed: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Disable default back button behavior
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Set up back button handling
        if let navigationController = navigationController {
            // Custom back gesture
            navigationController.interactivePopGestureRecognizer?.isEnabled = false
        }
    }
}

extension View {
    func onBackPressed(perform action: @escaping () -> Void) -> some View {
        self.background(
            BackButtonHandler(onBackPressed: action)
        )
        .onAppear {
            // Override back button using gesture
        }
        .gesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    if value.startLocation.x < 50 && value.translation.width > 100 {
                        action()
                    }
                }
        )
    }
}


extension View {
    @ViewBuilder
    func ifAvailableGlassEffect() -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular)
        } else {
            self
                .background(Color.black.opacity(0.35))
                .clipShape(Circle())
        }
    }
    
    
    @ViewBuilder
    func buttonGlassEffect() -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.clear)
        } else {
            self
                .background(Color.white)
                .clipShape(Circle())
        }
    }
    
    
    @ViewBuilder
    func cameraGlassBackground() -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular, in: .rect(cornerRadius: 24))
        } else {
            self
                .background(Color.black.opacity(0.5).blur(radius: 24))
                .clipShape(RoundedRectangle(cornerRadius: 24))
        }
    }
    
    @ViewBuilder
    func fillterGlassBackground() -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular, in: .rect(cornerRadius: 24))
        } else {
            self
                .background(Color.black.blur(radius: 24))
                .clipShape(RoundedRectangle(cornerRadius: 24))
        }
    }
}

// MARK: - Device Capabilities Helper
struct DeviceCapabilities {
    static func hasFlash() -> Bool {
        guard let backCamera = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: .back
        ).devices.first else {
            return false
        }
        return backCamera.hasTorch
    }
    
    static func hasFrontCamera() -> Bool {
        return AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: .front
        ).devices.first != nil
    }
}

extension View {
    var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
}
