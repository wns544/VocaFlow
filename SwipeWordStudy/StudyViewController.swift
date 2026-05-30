import UIKit

final class StudyViewController: UIViewController {
    private var session: StudySession
    private var showingAnswer = false
    private var isMovingCard = false

    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var wordLabel: UILabel!
    @IBOutlet weak var meaningLabel: UILabel!
    @IBOutlet weak var hintLabel: UILabel!

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
        title = "학습"
        view.backgroundColor = UIFactory.backgroundColor
        UIFactory.applyNavigationStyle(to: navigationController)
        setupStoryboardParts()
        setupGestures()
        showCurrentWord()
    }

    private func setupStoryboardParts() {
        progressLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        progressLabel.textColor = UIFactory.mutedTextColor

        cardView.backgroundColor = UIFactory.cardColor
        cardView.layer.cornerRadius = 22
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.12
        cardView.layer.shadowRadius = 18
        cardView.layer.shadowOffset = CGSize(width: 0, height: 8)

        wordLabel.font = UIFont.systemFont(ofSize: 42, weight: .bold)
        wordLabel.textColor = UIFactory.primaryColor
        wordLabel.textAlignment = .center
        wordLabel.numberOfLines = 0

        meaningLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        meaningLabel.textColor = UIFactory.textColor
        meaningLabel.textAlignment = .center
        meaningLabel.numberOfLines = 0

        hintLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        hintLabel.textColor = UIFactory.mutedTextColor
        hintLabel.textAlignment = .center
        hintLabel.numberOfLines = 0
    }

    private func setupGestures() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(toggleAnswer))
        cardView.addGestureRecognizer(tap)

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        cardView.addGestureRecognizer(pan)
    }

    private func showCurrentWord() {
        guard let word = session.currentWord else {
            showFinishAlert()
            return
        }

        showingAnswer = false
        wordLabel.text = word.term
        meaningLabel.text = ""
        hintLabel.text = "카드를 누르면 뜻 보기\n위로 넘기면 외움, 아래로 넘기면 다시 보기"
        progressLabel.text = "\(session.completedCount) / \(session.totalCount)"
        cardView.transform = .identity
        cardView.alpha = 1
    }

    @objc private func toggleAnswer() {
        guard let word = session.currentWord else { return }
        showingAnswer.toggle()

        if showingAnswer {
            meaningLabel.text = "\(word.meaning)\n\(word.reading)\n\(word.example)"
            hintLabel.text = "이제 위나 아래로 넘기면 됨"
        } else {
            meaningLabel.text = ""
            hintLabel.text = "카드를 누르면 뜻 보기\n위로 넘기면 외움, 아래로 넘기면 다시 보기"
        }
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard !isMovingCard else { return }
        let translation = gesture.translation(in: view)

        switch gesture.state {
        case .changed:
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
        isMovingCard = true
        UIView.animate(withDuration: 0.22, animations: {
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
            self.cardView.transform = .identity
        }
    }

    private func showFinishAlert() {
        let alert = UIAlertController(title: "끝", message: "오늘 단어를 다 봤습니다.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in
            self.navigationController?.popToRootViewController(animated: true)
        })
        present(alert, animated: true)
    }
}
