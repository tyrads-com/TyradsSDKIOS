import UIKit

extension UIColor {
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.hasPrefix("#") ? String(hexSanitized.dropFirst()) : hexSanitized

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let length = hexSanitized.count
        switch length {
        case 6:
            self.init(
                red: CGFloat((rgb & 0xFF0000) >> 16) / 255,
                green: CGFloat((rgb & 0x00FF00) >> 8) / 255,
                blue: CGFloat(rgb & 0x0000FF) / 255,
                alpha: 1.0
            )
        case 8:
            self.init(
                red: CGFloat((rgb & 0xFF000000) >> 24) / 255,
                green: CGFloat((rgb & 0x00FF0000) >> 16) / 255,
                blue: CGFloat((rgb & 0x0000FF00) >> 8) / 255,
                alpha: CGFloat(rgb & 0x000000FF) / 255
            )
        default:
            return nil
        }
    }

    var luminance: CGFloat {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }

    func fontColorForBackground() -> UIColor {
        luminance > 0.7 ? .black : .white
    }

    func darkerShade(factor: CGFloat = 0.66) -> UIColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return UIColor(red: r * factor, green: g * factor, blue: b * factor, alpha: a)
    }
}
