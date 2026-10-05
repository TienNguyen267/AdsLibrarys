//
//  RatingDialogView.swift
//  AdmobLibrary
//

import Combine
import StoreKit
import SwiftUI
import UIKit

@MainActor
final class RatingDialogPresenter {
    static let shared = RatingDialogPresenter()

    private var host: UIHostingController<RatingDialogContainer>?

    func present(configuration: RatingDialog.Configuration) -> Bool {
        guard host == nil else { return true }
        guard let presenter = Self.topViewController() else { return false }

        let model = RatingDialogModel(configuration: configuration)
        model.presenter = self
        let controller = UIHostingController(rootView: RatingDialogContainer(model: model))
        controller.view.backgroundColor = .clear
        controller.modalPresentationStyle = .overFullScreen
        controller.modalTransitionStyle = .crossDissolve
        host = controller
        presenter.present(controller, animated: true)
        return true
    }

    func dismiss(completion: (() -> Void)? = nil) {
        guard let host else {
            completion?()
            return
        }
        self.host = nil
        host.dismiss(animated: true, completion: completion)
    }

    private static func topViewController() -> UIViewController? {
        let root = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController
        return topViewController(from: root)
    }

    private static func topViewController(from base: UIViewController?) -> UIViewController? {
        if let navigation = base as? UINavigationController {
            return topViewController(from: navigation.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            return topViewController(from: tab.selectedViewController)
        }
        if let presented = base?.presentedViewController {
            return topViewController(from: presented)
        }
        return base
    }
}

@MainActor
final class RatingDialogModel: ObservableObject {
    enum Step {
        case rating
        case feedback
    }

    @Published var step: Step = .rating
    @Published var stars = 0
    @Published var feedback = ""
    @Published var feedbackError: String?
    @Published private(set) var displayTitle: String
    @Published private(set) var displayMessage: String

    let configuration: RatingDialog.Configuration
    weak var presenter: RatingDialogPresenter?
    private var didSubmitRating = false

    init(configuration: RatingDialog.Configuration) {
        self.configuration = configuration
        displayTitle = configuration.title
        displayMessage = "We’d greatly appreciate if you can rate us."
    }

    var imageName: String {
        switch stars {
        case 0: return "rate_0"
        case 1: return "rate_1"
        case 2: return "rate_2"
        case 3: return "rate_3"
        case 4: return "rate_4"
        case 5: return "rate_5"
        default: return "rate_1"
        }
    }

    func selectStars(_ value: Int) {
        stars = value
        switch value {
        case 0:
            displayTitle = "Making things better."
            displayMessage = "We’d greatly appreciate if you can rate us."
        case 1:
            displayTitle = "We're sorry to hear that."
            displayMessage = "Your feedback helps us improve."
        case 2:
            displayTitle = "Thanks for your honesty."
            displayMessage = "We’re working to do better."
        case 3:
            displayTitle = "Appreciate your feedback."
            displayMessage = "We'll keep improving from here."
        case 4:
            displayTitle = "Glad you liked it!"
            displayMessage = "We’ll make it even better."
        case 5:
            displayTitle = "Thank you!"
            displayMessage = "Your support means everything."
        default:
            displayTitle = "Oh, no!"
            displayMessage = "Please leave us some feedback"
        }
    }

    func rate() {
        guard step == .rating, !didSubmitRating else { return }
        configuration.onRate?(stars)
        if stars <= 3 {
            step = .feedback
            return
        }

        didSubmitRating = true
        let requestReview = RatingDialogStore.consumeInAppReviewChance()
        let appStoreID = configuration.appStoreID
        presenter?.dismiss {
            if requestReview {
                Self.requestSystemReview()
            } else {
                Self.openWriteReview(appStoreID: appStoreID)
                RatingDialogStore.markRated()
            }
        }
    }

    func later() {
        configuration.onMaybeLater?()
        if configuration.dismissOnLater {
            presenter?.dismiss()
        }
    }

    func cancelFeedback() {
        presenter?.dismiss()
    }

    func sendFeedback() {
        let body = feedback.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty else {
            feedbackError = "Feedback cannot be left blank"
            return
        }
        feedbackError = nil
        let configuration = configuration
        presenter?.dismiss {
            Self.openFeedbackEmail(configuration: configuration, body: body)
        }
    }

    private static func requestSystemReview() {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
            ?? UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        guard let scene else { return }
        if #available(iOS 16.0, *) {
            AppStore.requestReview(in: scene)
        } else {
            SKStoreReviewController.requestReview(in: scene)
        }
    }

    private static func openWriteReview(appStoreID: String) {
        let id = appStoreID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !id.isEmpty, let url = URL(string: "https://apps.apple.com/app/id\(id)?action=write-review") else {
            return
        }
        UIApplication.shared.open(url)
    }

    private static func openFeedbackEmail(configuration: RatingDialog.Configuration, body: String) {
        let subject = "Feedback App \(configuration.appName) | \(configuration.appVersion) | \(configuration.sdkVersion) | \(configuration.deviceName)"
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "&+=")
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: allowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: allowed) ?? ""
        guard let url = URL(string: "mailto:\(configuration.email)?subject=\(encodedSubject)&body=\(encodedBody)") else {
            return
        }
        UIApplication.shared.open(url)
    }
}

struct RatingDialogContainer: View {
    @ObservedObject var model: RatingDialogModel
    @StateObject private var keyboard = KeyboardObserver()

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture {
                    if model.step == .rating {
                        model.presenter?.dismiss()
                    } else {
                        model.cancelFeedback()
                    }
                }

            if model.step == .rating {
                RatingCard(model: model)
                    .transition(.scale(scale: 0.96).combined(with: .opacity))
            } else {
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    FeedbackSheet(model: model)
                }
                .padding(.bottom, keyboard.height)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: model.step)
    }
}

private struct RatingCard: View {
    @ObservedObject var model: RatingDialogModel
    @State private var emojiScale: CGFloat = 1

    var body: some View {
        VStack(spacing: 8) {
            ratingImage(named: model.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 75, height: 75)
                .scaleEffect(emojiScale)
                .animation(.spring(response: 0.28, dampingFraction: 0.55), value: emojiScale)

            Text(model.displayTitle)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color(red: 0.129, green: 0.129, blue: 0.129))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(minHeight: 36)

            Text(model.displayMessage)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color(red: 0.196, green: 0.322, blue: 0.749))
                .multilineTextAlignment(.center)
                .lineLimit(2)

            starRow
                .onChange(of: model.stars) { _ in
                    emojiScale = 0.82
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.5)) {
                        emojiScale = 1
                    }
                }

            Text("The best we can get :)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(red: 0, green: 0.122, blue: 0.757))
                .padding(.top, 4)

            Button(action: model.rate) {
                Text("Rate")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Capsule().fill(Color(uiColor: model.configuration.rateButtonColor)))
            }
            .padding(.top, 4)

            if model.configuration.showLaterButton {
                Button(action: model.later) {
                    Text(model.configuration.laterButtonTitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(red: 0.373, green: 0.373, blue: 0.373))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 14)
        .frame(maxWidth: 340)
        .background {
            ZStack(alignment: .top) {
                Color.white
                RatingWaveBackground()
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(.horizontal, 28)
    }

    private var starRow: some View {
        ScaleStarRating(model: model)
            .padding(.top, 4)
    }
}

private struct ScaleStarRating: View {
    @ObservedObject var model: RatingDialogModel
    @State private var popStar = 0
    @State private var popScale: CGFloat = 1

    private let starCount = 5
    private let starSize: CGFloat = 32
    private let spacing: CGFloat = 6

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(1...starCount, id: \.self) { index in
                Image(systemName: index <= model.stars ? "star.fill" : "star")
                    .font(.system(size: 28))
                    .foregroundStyle(index <= model.stars ? Color(red: 1, green: 0.76, blue: 0.03) : Color(white: 0.78))
                    .frame(width: starSize, height: 44)
                    .scaleEffect(index == popStar ? popScale : 1)
                    .allowsHitTesting(false)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            ratingImage(named: "rate_arrow")
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 50)
                .offset(x: 22, y: 0)
                .allowsHitTesting(false)
        }
        .overlay {
            StarDragCatcher(starCount: starCount, onSelect: selectStar)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
        }
        .accessibilityElement()
        .accessibilityLabel("Rating")
        .accessibilityValue("\(model.stars) stars")
        .accessibilityAdjustableAction { direction in
            let next = direction == .increment ? model.stars + 1 : model.stars - 1
            selectStar(min(max(next, 1), starCount))
        }
    }

    private func selectStar(_ star: Int) {
        guard star != model.stars else { return }
        model.selectStars(star)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        var reset = Transaction()
        reset.disablesAnimations = true
        withTransaction(reset) {
            popStar = star
            popScale = 0.62
        }
        withAnimation(.spring(response: 0.32, dampingFraction: 0.42)) {
            popScale = 1
        }
    }
}

private struct StarDragCatcher: UIViewRepresentable {
    var starCount: Int
    var onSelect: (Int) -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = true
        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handle(_:)))
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handle(_:)))
        view.addGestureRecognizer(pan)
        view.addGestureRecognizer(tap)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.starCount = starCount
        context.coordinator.onSelect = onSelect
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(starCount: starCount, onSelect: onSelect)
    }

    final class Coordinator: NSObject {
        nonisolated(unsafe) var starCount: Int
        nonisolated(unsafe) var onSelect: ((Int) -> Void)?

        init(starCount: Int, onSelect: @escaping (Int) -> Void) {
            self.starCount = starCount
            self.onSelect = onSelect
        }

        @objc nonisolated func handle(_ gesture: UIGestureRecognizer) {
            guard gesture.state == .began || gesture.state == .changed || gesture.state == .ended else { return }
            guard let view = gesture.view, view.bounds.width > 0 else { return }
            let x = min(max(gesture.location(in: view).x, 0), view.bounds.width - 0.01)
            let star = Int(floor(x / view.bounds.width * CGFloat(starCount))) + 1
            let callback = onSelect
            DispatchQueue.main.async {
                callback?(star)
            }
        }
    }
}

private struct FeedbackSheet: View {
    @ObservedObject var model: RatingDialogModel
    @FocusState private var isEditorFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                icon
                Text(model.configuration.appName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.black)
                    .padding(.top, 8)
            }

            HStack(spacing: 4) {
                Spacer(minLength: 0)
                ForEach(1...5, id: \.self) { index in
                    Image(systemName: index <= model.stars ? "star.fill" : "star")
                        .font(.system(size: 22))
                        .foregroundStyle(index <= model.stars ? Color(red: 0, green: 0.404, blue: 0) : Color(white: 0.5))
                }
                Spacer(minLength: 0)
            }

            ZStack(alignment: .topLeading) {
                if model.feedback.isEmpty {
                    Text("(Optional) Tell others what you think")
                        .font(.system(size: 15))
                        .foregroundStyle(Color(white: 0.62))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 8)
                        .allowsHitTesting(false)
                }
                TextEditor(text: feedbackBinding)
                    .focused($isEditorFocused)
                    .font(.system(size: 15))
                    .frame(minHeight: 88)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .stroke(Color(white: 0.74), lineWidth: 0.5)
            )

            HStack {
                Text("Optional")
                Spacer()
                Text("\(model.feedback.count)/500")
            }
            .font(.system(size: 11))
            .foregroundStyle(Color(white: 0.5))

            if let feedbackError = model.feedbackError {
                Text(feedbackError)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.red)
            }

            HStack(spacing: 10) {
                Button(action: model.cancelFeedback) {
                    Text("Cancel")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color(red: 0, green: 0.404, blue: 0))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(Color(white: 0.88), lineWidth: 1)
                                )
                        )
                }

                Button(action: model.sendFeedback) {
                    Text("Send")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color(red: 0, green: 0.404, blue: 0))
                        )
                }
            }
            .padding(.top, 4)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .clipShape(TopRoundedRectangle(radius: 20))
        .onTapGesture {}
    }

    private var feedbackBinding: Binding<String> {
        Binding(
            get: { model.feedback },
            set: { newValue in
                model.feedback = String(newValue.prefix(500))
                if model.feedbackError != nil, !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    model.feedbackError = nil
                }
            }
        )
    }

    @ViewBuilder
    private var icon: some View {
        if let icon = model.configuration.icon {
            Image(uiImage: icon)
                .resizable()
                .scaledToFill()
                .frame(width: 45, height: 45)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        } else {
            ratingImage(named: "rate_0")
                .resizable()
                .scaledToFit()
                .frame(width: 45, height: 45)
        }
    }
}

private struct RatingWaveBackground: View {
    var body: some View {
        Canvas { context, size in
            let colors = [
                Color(red: 0.949, green: 0.792, blue: 0.314).opacity(0.55),
                Color(red: 0.949, green: 0.792, blue: 0.314).opacity(0.38),
                Color(red: 0.949, green: 0.792, blue: 0.314).opacity(0.28)
            ]
            let phases: [CGFloat] = [0.2, 0.55, 0.85]
            let amplitudes: [CGFloat] = [16, 12, 8]
            for index in colors.indices {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: 0))
                let steps = 48
                for step in 0...steps {
                    let progress = CGFloat(step) / CGFloat(steps)
                    let x = size.width * progress
                    let wave = sin((progress + phases[index]) * .pi * 2) * amplitudes[index]
                    let y = size.height * (0.28 + CGFloat(index) * 0.12) + wave
                    path.addLine(to: CGPoint(x: x, y: y))
                }
                path.addLine(to: CGPoint(x: size.width, y: 0))
                path.closeSubpath()
                context.fill(path, with: .color(colors[index]))
            }
        }
        .frame(height: 92)
        .frame(maxWidth: .infinity)
        .allowsHitTesting(false)
    }
}

private nonisolated struct TopRoundedRectangle: Shape {
    var radius: CGFloat

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: [.topLeft, .topRight],
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

private func ratingImage(named name: String) -> Image {
    if let image = AdmobLibraryAssets.image(named: name) {
        return Image(uiImage: image)
    }
    return Image(systemName: "face.smiling")
}

@MainActor
private final class KeyboardObserver: ObservableObject {
    @Published var height: CGFloat = 0
    private nonisolated(unsafe) var token: NSObjectProtocol?

    init() {
        token = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillChangeFrameNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            let minY = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.minY ?? 0
            Task { @MainActor [weak self] in
                let screenHeight = UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .first?
                    .screen.bounds.height ?? 0
                self?.height = max(0, screenHeight - minY)
            }
        }
    }

    deinit {
        if let token {
            NotificationCenter.default.removeObserver(token)
        }
    }
}
