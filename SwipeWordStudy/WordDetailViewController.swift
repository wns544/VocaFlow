import UIKit

final class WordDetailViewController: UIViewController {
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var stateLabel: UILabel!
    @IBOutlet weak var stateDescriptionLabel: UILabel!
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
    }

    private func fillWord() {
        guard let word = word else { return }

        stateLabel.text = "현재 상태: \(word.state.rawValue)"
        termLabel.text = word.term
        meaningLabel.text = "뜻\n\(word.meaning)"
        readingLabel.text = "읽기\n\(word.reading)"
        if word.exampleMeaning.isEmpty {
            exampleLabel.text = "예문\n\(word.example)"
        } else {
            exampleLabel.text = "예문\n\(word.example)\n\n예문뜻\n\(word.exampleMeaning)"
        }

        let color: UIColor
        let stateDescription: String
        switch word.state {
        case .new:
            color = UIFactory.mutedTextColor
            stateDescription = "아직 학습 전 단어"
        case .memorized:
            color = UIFactory.secondaryColor
            stateDescription = "외운 단어로 표시됨"
        case .review:
            color = UIFactory.warningColor
            stateDescription = "다시 봐야 할 단어"
        }

        stateLabel.textColor = color
        stateLabel.backgroundColor = color.withAlphaComponent(0.12)
        stateDescriptionLabel.text = stateDescription
        stateDescriptionLabel.textColor = color
    }
}
