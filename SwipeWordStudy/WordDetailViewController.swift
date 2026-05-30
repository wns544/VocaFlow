import UIKit

final class WordDetailViewController: UIViewController {
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var stateLabel: UILabel!
    @IBOutlet weak var termLabel: UILabel!
    @IBOutlet weak var meaningLabel: UILabel!
    @IBOutlet weak var readingLabel: UILabel!
    @IBOutlet weak var exampleLabel: UILabel!

    private var word: Word?

    func configure(word: Word) {
        self.word = word
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = word?.term ?? "단어"
        view.backgroundColor = UIFactory.backgroundColor
        UIFactory.applyNavigationStyle(to: navigationController)
        setupStoryboardParts()
        fillWord()
    }

    private func setupStoryboardParts() {
        cardView.layer.cornerRadius = 22
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.10
        cardView.layer.shadowRadius = 16
        cardView.layer.shadowOffset = CGSize(width: 0, height: 8)

        stateLabel.layer.cornerRadius = 12
        stateLabel.layer.masksToBounds = true
        stateLabel.font = UIFont.systemFont(ofSize: 13, weight: .semibold)

        termLabel.font = UIFont.systemFont(ofSize: 36, weight: .bold)
        termLabel.textColor = UIFactory.primaryColor

        [meaningLabel, readingLabel, exampleLabel].forEach {
            $0?.font = UIFont.systemFont(ofSize: 17)
            $0?.textColor = UIFactory.textColor
            $0?.numberOfLines = 0
        }
    }

    private func fillWord() {
        guard let word = word else { return }

        stateLabel.text = word.state.rawValue
        termLabel.text = word.term
        meaningLabel.text = "뜻\n\(word.meaning)"
        readingLabel.text = "읽기\n\(word.reading)"
        exampleLabel.text = "예문\n\(word.example)"

        let color: UIColor
        switch word.state {
        case .new:
            color = UIFactory.mutedTextColor
        case .memorized:
            color = UIFactory.secondaryColor
        case .review:
            color = UIFactory.warningColor
        }

        stateLabel.textColor = color
        stateLabel.backgroundColor = color.withAlphaComponent(0.12)
    }
}
