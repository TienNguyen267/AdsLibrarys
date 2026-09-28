import UIKit

public enum AdmobLibraryAssets {
    private static let bundleName = "AdmobLibraryResources"

    static public var bundle: Bundle = {
        let candidates = [
            Bundle.main.resourceURL,
            Bundle(for: BundleToken.self).resourceURL,
            Bundle(for: BundleToken.self).resourceURL?.appendingPathComponent("Frameworks")
        ]
        for candidate in candidates {
            guard let url = candidate?.appendingPathComponent("\(bundleName).bundle"),
                  let bundle = Bundle(url: url) else {
                continue
            }
            return bundle
        }
        if let url = Bundle.main.url(forResource: bundleName, withExtension: "bundle"),
           let bundle = Bundle(url: url) {
            return bundle
        }
        return Bundle(for: BundleToken.self)
    }()

    static public func image(named name: String) -> UIImage? {
        UIImage(named: name, in: bundle, compatibleWith: nil)
    }
}

private final class BundleToken {}
