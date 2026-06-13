import UIKit

final class StudyViewController: UIViewController {
    private var session: StudySession
    private var showingAnswer = false
    private var isMovingCard = false
    private let defaultBackgroundColor = UIColor(red: 0.96, green: 0.98, blue: 1.0, alpha: 1.0)

    @IBOutlet weak var progressBarImageView: UIImageView!
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var wordLabel: UILabel!
    @IBOutlet weak var meaningLabel: UILabel!
    @IBOutlet weak var hintLabel: UILabel!
    @IBOutlet weak var examplePreviewSwitch: UISwitch!

    init(session: StudySession) {
        self.session = session
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        session = StudySession(words: WordStore.shared.words)
        super.init(coder: coder)
    }

    func configure(session: StudySession) {
        self.session = session
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "쇼츠 학습"
        UIFactory.applyNavigationStyle(to: navigationController)
        setupStoryboardParts()
        setupGestures()
        showCurrentWord()
    }

    private func setupStoryboardParts() {
        view.backgroundColor = defaultBackgroundColor
        cardView.layer.cornerRadius = 22
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.12
        cardView.layer.shadowRadius = 18
        cardView.layer.shadowOffset = CGSize(width: 0, height: 8)
        examplePreviewSwitch.isOn = false
    }

    private func setupGestures() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(toggleAnswer))
        cardView.addGestureRecognizer(tap)

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        cardView.addGestureRecognizer(pan)
    }

    private func showCurrentWord() {
        guard let word = session.currentWord else {
            showResult()
            return
        }

        showingAnswer = false
        wordLabel.text = word.term
        showFrontText(for: word)
        progressLabel.text = "진행 \(session.completedCount) / \(session.totalCount)"
        statusLabel.text = "외움 \(session.memorizedCount)  다시 \(session.reviewCount)  남음 \(session.queue.count)"
        updateProgressBar()
        view.backgroundColor = defaultBackgroundColor
        cardView.transform = .identity
        cardView.alpha = 1
    }

    private func updateProgressBar() {
        let progress = session.totalCount == 0
            ? 0
            : CGFloat(session.completedCount) / CGFloat(session.totalCount)
        let imageSize = progressBarImageView.bounds.size == .zero
            ? CGSize(width: 320, height: 16)
            : progressBarImageView.bounds.size
        progressBarImageView.image = UIFactory.progressBarImage(progress: progress, size: imageSize)
    }

    @objc private func toggleAnswer() {
        guard let word = session.currentWord else { return }
        let willShowAnswer = !showingAnswer
        let options: UIView.AnimationOptions = willShowAnswer ? .transitionFlipFromRight : .transitionFlipFromLeft

        UIView.transition(with: cardView, duration: 0.35, options: options, animations: {
            self.showingAnswer = willShowAnswer
            if willShowAnswer {
                self.meaningLabel.attributedText = self.answerText(for: word)
                self.hintLabel.text = ""
            } else {
                self.showFrontText(for: word)
            }
        }, completion: nil)
    }

    @IBAction func examplePreviewChanged() {
        guard !showingAnswer, let word = session.currentWord else { return }
        showFrontText(for: word)
    }

    private func showFrontText(for word: Word) {
        if examplePreviewSwitch.isOn, !word.example.isEmpty {
            meaningLabel.attributedText = previewText(for: word)
            hintLabel.text = "카드를 누르면 뜻과 예문뜻이 나와요"
        } else {
            meaningLabel.attributedText = nil
            hintLabel.text = "카드를 눌러서 뜻을 볼까요?"
        }
    }

    private func previewText(for word: Word) -> NSAttributedString {
        return cardText(parts: [word.example], fontSize: 16)
    }

    private func answerText(for word: Word) -> NSAttributedString {
        var parts = [word.meaning, "[\(word.reading)]"]
        if !word.example.isEmpty {
            parts.append(word.example)
        }
        if !word.exampleMeaning.isEmpty {
            parts.append(word.exampleMeaning)
        }

        return cardText(parts: parts, fontSize: 18)
    }

    private func cardText(parts: [String], fontSize: CGFloat) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineSpacing = 6
        paragraphStyle.paragraphSpacing = 12

        let text = parts.filter { !$0.isEmpty }.joined(separator: "\n")
        let attributes: [NSAttributedString.Key: Any] = [
            .paragraphStyle: paragraphStyle,
            .font: UIFont.systemFont(ofSize: fontSize, weight: .medium),
            .foregroundColor: UIColor.darkText
        ]

        return NSAttributedString(string: text, attributes: attributes)
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard !isMovingCard else { return }
        let translation = gesture.translation(in: view)

        switch gesture.state {
        case .changed:
            updateBackgroundColor(for: translation.y)
            cardView.transform = CGAffineTransform(translationX: translation.x * 0.25, y: translation.y)
                .rotated(by: -translation.y / 900)
        case .ended:
            finishPan(translationY: translation.y)
        case .cancelled, .failed:
            moveCardBack()
        default:
            break
        }
    }

    private func finishPan(translationY: CGFloat) {
        if translationY < -110 {
            moveCardOut(up: true)
        } else if translationY > 110 {
            moveCardOut(up: false)
        } else {
            moveCardBack()
        }
    }

    private func moveCardOut(up: Bool) {
        guard !isMovingCard else { return }
        isMovingCard = true
        UIView.animate(withDuration: 0.22, animations: {
            self.view.backgroundColor = up ? UIFactory.successSoftColor : UIFactory.warningSoftColor
            self.cardView.transform = CGAffineTransform(translationX: up ? -80 : 80, y: up ? -700 : 700)
                .rotated(by: up ? 0.18 : -0.18)
            self.cardView.alpha = 0
        }, completion: { _ in
            if up {
                self.session.markCurrentAsMemorized()
            } else {
                self.session.markCurrentForReview()
            }
            self.isMovingCard = false
            self.showCurrentWord()
        })
    }

    private func moveCardBack() {
        UIView.animate(withDuration: 0.2) {
            self.view.backgroundColor = self.defaultBackgroundColor
            self.cardView.transform = .identity
        }
    }

    private func updateBackgroundColor(for translationY: CGFloat) {
        let distance = min(abs(translationY) / 140, 1)
        guard distance > 0.08 else {
            view.backgroundColor = defaultBackgroundColor
            return
        }

        let targetColor = translationY < 0 ? UIFactory.successSoftColor : UIFactory.warningSoftColor
        view.backgroundColor = defaultBackgroundColor.blended(with: targetColor, progress: distance)
    }

    @IBAction func undoLastCard() {
        guard !isMovingCard else { return }
        if session.undoLastAction() {
            showCurrentWord()
        } else {
            hintLabel.text = "되돌릴 카드가 아직 없어요"
        }
    }

    private func showResult() {
        session.markSessionCompleted()
        let resultViewController = storyboard?.instantiateViewController(withIdentifier: "ResultViewController") as? ResultViewController
            ?? ResultViewController()
        resultViewController.configure(
            totalCount: session.totalCount,
            memorizedCount: session.memorizedCount,
            reviewCount: session.reviewCount
        )
        navigationController?.pushViewController(resultViewController, animated: true)
    }
}
