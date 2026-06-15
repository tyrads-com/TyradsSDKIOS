import SwiftUI
import UIKit
import CoreText

// MARK: - Bundled fonts (Poppins)
// The Flutter SDK renders the premium widget in Poppins via google_fonts.
// We bundle the same family and register it at first use.

enum TyradsTheme {
    /// Registers the bundled Poppins faces exactly once.
    private static let fontsRegistered: Void = {
        let faces = ["Poppins-Light", "Poppins-Regular", "Poppins-SemiBold", "Poppins-Bold"]
        for face in faces {
            guard let url = fontURL(face) else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }()

    private static func fontURL(_ name: String) -> URL? {
        Bundle.module.url(forResource: name, withExtension: "ttf", subdirectory: "Fonts")
            ?? Bundle.module.url(forResource: name, withExtension: "ttf")
    }

    /// Poppins font for the given size/weight, falling back to the system font
    /// if registration ever fails.
    static func poppins(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        _ = fontsRegistered
        let face: String
        switch weight {
        case .ultraLight, .thin, .light: face = "Poppins-Light"
        case .medium, .semibold:         face = "Poppins-SemiBold"
        case .bold, .heavy, .black:      face = "Poppins-Bold"
        default:                         face = "Poppins-Regular"
        }
        return .custom(face, size: size)
    }
}

// MARK: - Bundled images
// The images ship as loose resource files (.process copies them as-is, not into
// an asset catalog), so UIImage(named:)/Image(name:bundle:) can't find them by
// name. Load them directly by URL from Bundle.module instead.

enum TyradsBundleImage {
    static func uiImage(_ name: String) -> UIImage? {
        for ext in ["png", "jpeg", "jpg"] {
            if let url = Bundle.module.url(forResource: name, withExtension: ext),
               let image = UIImage(contentsOfFile: url.path) {
                return image
            }
        }
        return UIImage(named: name, in: .module, compatibleWith: nil)
    }
}

extension Image {
    /// Loads a bundled SDK image as a tintable template.
    static func tyradsTemplate(_ name: String) -> Image {
        let ui = (TyradsBundleImage.uiImage(name) ?? UIImage()).withRenderingMode(.alwaysTemplate)
        return Image(uiImage: ui)
    }

    /// Loads a bundled SDK image preserving its colors.
    static func tyradsAsset(_ name: String) -> Image {
        Image(uiImage: TyradsBundleImage.uiImage(name) ?? UIImage())
    }
}
