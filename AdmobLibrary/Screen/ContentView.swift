//
//  ContentView.swift
//  AdmobLibrary
//
//  Created by Tien Nguyen on 8/7/26.
//

import SwiftUI
import AdmobLibrary
import AppTrackingTransparency
import UserNotifications

struct ContentView: View {

    @State private var showNetworkAlert = false
    @State private var hasRequestedATT = false
    @State private var hasRequestedNotification = false
    @State private var isViewAppeared = false

    private let sections: [(title: String, items: [AdExample])] = [
        ("Banner", [.banner, .bannerCollapsible]),
        ("Native", [
            .nativeMedium,
            .nativeSmallPlay,
            .nativeSmallBanner,
            .nativeCollapsible,
            .nativeCollapsibleClose,
            .nativeFullscreen
        ]),
        ("Fullscreen", [.interstitial, .rewarded, .rewardedInterstitial, .appOpen])
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Ad Examples")
                            .font(.largeTitle.bold())
                        Text("Chọn một loại quảng cáo để xem example. Quảng cáo chỉ load khi bạn mở màn đó.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    ForEach(sections, id: \.title) { section in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(section.title.uppercased())
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 20)

                            VStack(spacing: 10) {
                                ForEach(section.items) { item in
                                    NavigationLink(value: item) {
                                        AdExampleRow(example: item)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                }
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: AdExample.self) { example in
                AdExampleScreen(example: example, showNetworkAlert: $showNetworkAlert)
            }
            .alert("home.no_internet".localized(), isPresented: $showNetworkAlert) {
                Button("home.ok".localized(), role: .cancel) {
                    showNetworkAlert = false
                    showWiFiInstruction()
                }
            } message: {
                Text("home.no_internet_message".localized())
            }
            .onAppear {
                if !isViewAppeared {
                    isViewAppeared = true
                    requestATTrackingPermission()
                }
            }
        }
    }

    // MARK: - ATT Permission
    private func requestATTrackingPermission() {
        guard !hasRequestedATT else { return }

        let currentStatus = ATTrackingManager.trackingAuthorizationStatus
        guard currentStatus == .notDetermined else {
            hasRequestedATT = true
            return
        }

        ATTrackingManager.requestTrackingAuthorization { status in
            DispatchQueue.main.async {
                self.hasRequestedATT = true
                requestNotificationPermission()
                switch status {
                case .authorized:
                    print("✅ ATT permission granted")
                case .denied:
                    print("❌ ATT permission denied")
                case .restricted:
                    print("⚠️ ATT permission restricted")
                case .notDetermined:
                    print("❓ ATT permission not determined")
                @unknown default:
                    print("❓ ATT permission unknown status")
                }
            }
        }
    }

    private func requestNotificationPermission() {
        guard !hasRequestedNotification else { return }

        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let status = settings.authorizationStatus
            DispatchQueue.main.async {
                guard status == .notDetermined else {
                    self.hasRequestedNotification = true
                    return
                }

                UNUserNotificationCenter.current().requestAuthorization(
                    options: [.alert, .badge, .sound]
                ) { granted, _ in
                    print("Notification permission: \(granted)")
                }
            }
        }
    }

    private func showWiFiInstruction() {
        let alert = UIAlertController(
            title: "home.wifi_instruction_title".localized(),
            message: "home.wifi_instruction_message".localized(),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "home.ok".localized(), style: .default))

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(alert, animated: true)
        }
    }
}

private struct AdExampleRow: View {
    let example: AdExample

    var body: some View {
        HStack(spacing: 14) {
            Text(example.badge)
                .font(.caption.weight(.bold))
                .foregroundStyle(example.tint)
                .frame(width: 44, height: 44)
                .background(example.tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 3) {
                Text(example.title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(example.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    ContentView()
}
