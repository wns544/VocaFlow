import UIKit

enum UIFactory {
    static let backgroundColor = UIColor(red: 0.94, green: 0.96, blue: 0.97, alpha: 1.0)
    static let cardColor = UIColor.white
    static let primaryColor = UIColor(red: 0.07, green: 0.16, blue: 0.24, alpha: 1.0)
    static let secondaryColor = UIColor(red: 0.00, green: 0.48, blue: 0.47, alpha: 1.0)
    static let accentColor = UIColor(red: 0.25, green: 0.35, blue: 0.83, alpha: 1.0)
    static let warningColor = UIColor(red: 0.85, green: 0.34, blue: 0.22, alpha: 1.0)
    static let textColor = UIColor(red: 0.13, green: 0.17, blue: 0.22, alpha: 1.0)
    static let mutedTextColor = UIColor(red: 0.45, green: 0.50, blue: 0.56, alpha: 1.0)
    static let lineColor = UIColor(red: 0.86, green: 0.89, blue: 0.92, alpha: 1.0)
    static let successSoftColor = UIColor(red: 0.88, green: 0.97, blue: 0.91, alpha: 1.0)
    static let warningSoftColor = UIColor(red: 1.00, green: 0.92, blue: 0.89, alpha: 1.0)

    static func titleLabel(_ text: String, size: CGFloat = 28) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFont.systemFont(ofSize: size, weight: .bold)
        label.textColor = primaryColor
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }

    static func bodyLabel(_ text: String, size: CGFloat = 16) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFont.systemFont(ofSize: size, weight: .regular)
        label.textColor = mutedTextColor
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }

    static func button(_ title: String, color: UIColor = primaryColor) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        button.backgroundColor = color
        button.layer.cornerRadius = 14
        button.contentEdgeInsets = UIEdgeInsets(top: 14, left: 18, bottom: 14, right: 18)
        return button
    }

    static func secondaryButton(_ title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(primaryColor, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.backgroundColor = cardColor
        button.layer.cornerRadius = 14
        button.layer.borderColor = lineColor.cgColor
        button.layer.borderWidth = 1
        button.contentEdgeInsets = UIEdgeInsets(top: 13, left: 18, bottom: 13, right: 18)
        return button
    }

    static func cardView(cornerRadius: CGFloat = 20) -> UIView {
        let view = UIView()
        view.backgroundColor = cardColor
        view.layer.cornerRadius = cornerRadius
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.08
        view.layer.shadowRadius = 18
        view.layer.shadowOffset = CGSize(width: 0, height: 10)
        return view
    }

    static func captionLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        label.textColor = mutedTextColor
        label.numberOfLines = 0
        return label
    }

    static func badgeLabel(_ text: String, color: UIColor) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        label.textColor = color
        label.textAlignment = .center
        label.backgroundColor = color.withAlphaComponent(0.12)
        label.layer.cornerRadius = 11
        label.layer.masksToBounds = true
        return label
    }

    static func applyNavigationStyle(to navigationController: UINavigationController?) {
        navigationController?.navigationBar.tintColor = primaryColor
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: primaryColor,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
    }

    static func progressBarImage(progress: CGFloat, size: CGSize) -> UIImage {
        let safeProgress = max(0, min(1, progress))
        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale

        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            let rect = CGRect(origin: .zero, size: size)
            let radius = size.height / 2
            let trackRect = rect.insetBy(dx: 0, dy: 1)
            let fillWidth = max(size.height, trackRect.width * safeProgress)
            let fillRect = CGRect(x: trackRect.minX, y: trackRect.minY, width: fillWidth, height: trackRect.height)

            lineColor.setFill()
            UIBezierPath(roundedRect: trackRect, cornerRadius: radius).fill()

            secondaryColor.setFill()
            UIBezierPath(roundedRect: fillRect, cornerRadius: radius).fill()

            UIColor.white.withAlphaComponent(0.65).setFill()
            let shineRect = CGRect(x: trackRect.minX + 3, y: trackRect.minY + 2, width: max(0, fillWidth - 6), height: 2)
            UIBezierPath(roundedRect: shineRect, cornerRadius: 1).fill()

            context.cgContext.setLineWidth(1)
            UIColor.white.withAlphaComponent(0.9).setStroke()
            UIBezierPath(roundedRect: trackRect, cornerRadius: radius).stroke()
        }
    }
}

extension UIColor {
    func blended(with color: UIColor, progress: CGFloat) -> UIColor {
        let amount = max(0, min(1, progress))
        var red1: CGFloat = 0
        var green1: CGFloat = 0
        var blue1: CGFloat = 0
        var alpha1: CGFloat = 0
        var red2: CGFloat = 0
        var green2: CGFloat = 0
        var blue2: CGFloat = 0
        var alpha2: CGFloat = 0

        getRed(&red1, green: &green1, blue: &blue1, alpha: &alpha1)
        color.getRed(&red2, green: &green2, blue: &blue2, alpha: &alpha2)

        return UIColor(
            red: red1 + (red2 - red1) * amount,
            green: green1 + (green2 - green1) * amount,
            blue: blue1 + (blue2 - blue1) * amount,
            alpha: alpha1 + (alpha2 - alpha1) * amount
        )
    }
}
