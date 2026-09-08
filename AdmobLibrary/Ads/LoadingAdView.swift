//
//  LoadingAdView.swift
//  ReverseAudioIOS
//
//  Created by Tien Nguyen on 11/10/25.
//

import SwiftUI
import Lottie

struct LoadingAdView: View {
    var body: some View {
        ZStack {
            // Background với màu đen mờ
            Color.white
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                // Lottie Animation
                LottieView(animation: .named("gifloading"))
                    .playing(loopMode: .loop)
                    .frame(width: 200, height: 200)
                
                // Text "Loading Ads..."
                Text("Loading Ads...")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.black)
            }
        }
    }
}

// Loading Ad Window Controller
class LoadingAdViewController: UIViewController {
    private var hostingController: UIHostingController<LoadingAdView>?
    private var window: UIWindow?
    
    static let shared = LoadingAdViewController()
    
    private override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func show() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Tìm window scene hiện tại
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
                print("❌ Không tìm thấy window scene")
                return
            }
            
            // Tạo window mới cho loading
            let window = UIWindow(windowScene: windowScene)
            window.windowLevel = .alert + 1 // Hiển thị trên tất cả
            window.backgroundColor = .clear
            
            // Tạo hosting controller với LoadingAdView
            let loadingView = LoadingAdView()
            let hostingController = UIHostingController(rootView: loadingView)
            hostingController.view.backgroundColor = .clear
            
            window.rootViewController = hostingController
            window.makeKeyAndVisible()
            
            self.window = window
            self.hostingController = hostingController
            
            print("✅ Đã hiển thị loading ad view")
        }
    }
    
    func hide() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.window?.isHidden = true
            self.window = nil
            self.hostingController = nil
            
            print("✅ Đã ẩn loading ad view")
        }
    }
}

#Preview {
    LoadingAdView()
}

