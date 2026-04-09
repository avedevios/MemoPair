//
//  CardCell.swift
//  MemoPair
//
import UIKit

// Palette of colors for card pairs
let cardPairColors: [UIColor] = [
    UIColor(red: 0.29, green: 0.56, blue: 0.89, alpha: 1), // blue
    UIColor(red: 0.35, green: 0.78, blue: 0.65, alpha: 1), // teal
    UIColor(red: 0.95, green: 0.61, blue: 0.27, alpha: 1), // orange
    UIColor(red: 0.85, green: 0.40, blue: 0.55, alpha: 1), // pink
    UIColor(red: 0.60, green: 0.45, blue: 0.85, alpha: 1), // purple
    UIColor(red: 0.40, green: 0.75, blue: 0.40, alpha: 1), // green
    UIColor(red: 0.90, green: 0.75, blue: 0.25, alpha: 1), // yellow
    UIColor(red: 0.45, green: 0.70, blue: 0.85, alpha: 1), // sky
]

class CardCell: UICollectionViewCell {

    let label = UILabel()
    let backgroundImageView = UIImageView()
    let checkmarkLabel = UILabel()
    private let gradientLayer = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)

        layer.cornerRadius = 16
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.15
        layer.shadowOffset = CGSize(width: 0, height: 3)
        layer.shadowRadius = 6

        contentView.layer.cornerRadius = 16
        contentView.clipsToBounds = true

        gradientLayer.cornerRadius = 16
        contentView.layer.insertSublayer(gradientLayer, at: 0)

        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(backgroundImageView)

        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])

        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.font = UIFont.boldSystemFont(ofSize: 28)
        label.numberOfLines = 2
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.4
        label.textColor = .white
        contentView.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            label.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.85),
            label.heightAnchor.constraint(lessThanOrEqualTo: contentView.heightAnchor, multiplier: 0.85)
        ])

        checkmarkLabel.translatesAutoresizingMaskIntoConstraints = false
        checkmarkLabel.text = "✓"
        checkmarkLabel.font = UIFont.boldSystemFont(ofSize: 14)
        checkmarkLabel.textColor = UIColor.white.withAlphaComponent(0.9)
        checkmarkLabel.isHidden = true
        contentView.addSubview(checkmarkLabel)

        NSLayoutConstraint.activate([
            checkmarkLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            checkmarkLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = contentView.bounds
    }

    func configure(with text: String?, isFaceUp: Bool, pairID: Int = 0, isMatched: Bool = false, animated: Bool = false) {
        let options: UIView.AnimationOptions = isFaceUp ? .transitionFlipFromLeft : .transitionFlipFromRight
        if animated {
            UIView.transition(with: contentView, duration: 0.3, options: [options, .showHideTransitionViews], animations: {
                self.updateAppearance(text: text, isFaceUp: isFaceUp, pairID: pairID, isMatched: isMatched)
            }, completion: nil)
        } else {
            updateAppearance(text: text, isFaceUp: isFaceUp, pairID: pairID, isMatched: isMatched)
        }
    }

    private func updateAppearance(text: String?, isFaceUp: Bool, pairID: Int, isMatched: Bool) {
        if isFaceUp {
            backgroundImageView.image = nil
            if isMatched {
                let top = UIColor(red: 0.25, green: 0.75, blue: 0.45, alpha: 1).cgColor
                let bottom = UIColor(red: 0.15, green: 0.60, blue: 0.35, alpha: 1).cgColor
                gradientLayer.colors = [top, bottom]
                checkmarkLabel.isHidden = false
            } else {
                let base = cardPairColors[pairID % cardPairColors.count]
                let top = base.withAlphaComponent(0.9).cgColor
                let bottom = base.darker().cgColor
                gradientLayer.colors = [top, bottom]
                checkmarkLabel.isHidden = true
            }
            gradientLayer.startPoint = CGPoint(x: 0, y: 0)
            gradientLayer.endPoint = CGPoint(x: 1, y: 1)
            contentView.backgroundColor = .clear
            label.text = text
        } else {
            gradientLayer.colors = nil
            backgroundImageView.image = UIImage(named: "cardBack")
            contentView.backgroundColor = .clear
            label.text = ""
            checkmarkLabel.isHidden = true
        }
    }

    func shake() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.duration = 0.4
        animation.values = [-8, 8, -6, 6, -4, 4, 0]
        layer.add(animation, forKey: "shake")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension UIColor {
    func darker(by factor: CGFloat = 0.25) -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return UIColor(hue: h, saturation: min(s + 0.1, 1), brightness: max(b - factor, 0), alpha: a)
    }
}
