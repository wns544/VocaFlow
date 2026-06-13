import UIKit

final class QuizViewController: UIViewController {
    @IBOutlet weak var progressBarImageView: UIImageView!
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet weak var answerField: UITextField!
    @IBOutlet weak var checkButton: UIButton!
    @IBOutlet weak var dontKnowButton: UIButton!
    @IBOutlet weak var feedbackLabel: UILabel!

    private var words: [Word] = []
    private var bookID: String?
    private var sessionIndex: Int?
    private var totalCount = 0
    private var correctCount = 0
    private var reviewedTerms: Set<String> = []
    private var didShowResult = false
    private var isNormalizingAnswer = false
    private var isWaitingForNextQuestion = false
    private var originalAdditionalSafeAreaInsets = UIEdgeInsets.zero

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "타이핑 학습"
        if words.isEmpty {
            let quickSession = WordStore.shared.nextQuickStudySession()
            words = quickSession.words.shuffled()
            totalCount = quickSession.words.count
            bookID = quickSession.book.id
            sessionIndex = quickSession.index
        }
        answerField.delegate = self
        answerField.addTarget(self, action: #selector(normalizeAnswerText), for: .editingChanged)
        setupKeyboardDismissGesture()
        setupKeyboardObservers()
        setupQuestionLabel()
        setupActionButtons()
        scoreLabel.isHidden = true
        showQuestion()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func configure(words: [Word], bookID: String? = nil, sessionIndex: Int? = nil) {
        self.words = words.shuffled()
        self.totalCount = words.count
        self.bookID = bookID
        self.sessionIndex = sessionIndex
    }

    private func setupKeyboardDismissGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    private func setupKeyboardObservers() {
        originalAdditionalSafeAreaInsets = additionalSafeAreaInsets
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChangeFrame),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    private func setupQuestionLabel() {
        questionLabel.adjustsFontSizeToFitWidth = false
        questionLabel.lineBreakMode = .byWordWrapping
        questionLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        questionLabel.setContentHuggingPriority(.required, for: .vertical)
        answerField.setContentCompressionResistancePriority(.required, for: .vertical)
        feedbackLabel.numberOfLines = 0
        feedbackLabel.lineBreakMode = .byWordWrapping
        feedbackLabel.setContentCompressionResistancePriority(.required, for: .vertical)
    }

    private func setupActionButtons() {
        checkButton.layer.cornerRadius = 0
        dontKnowButton.layer.cornerRadius = 0
        dontKnowButton.layer.borderWidth = 1
        dontKnowButton.layer.borderColor = UIColor(red: 0.86, green: 0.91, blue: 0.95, alpha: 1).cgColor
        dontKnowButton.backgroundColor = .white
        dontKnowButton.setTitleColor(UIFactory.primaryColor, for: .normal)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        answerField.becomeFirstResponder()
    }

    private func showQuestion() {
        guard let word = words.first else {
            progressLabel.text = "문제 끝"
            scoreLabel.text = "점수 \(correctCount) / \(totalCount)"
            feedbackLabel.text = "타이핑 학습 끝"
            questionLabel.text = "-"
            answerField.text = ""
            updateProgressBar()
            showResultLater()
            return
        }

        progressLabel.text = "진행 \(correctCount) / \(totalCount)"
        scoreLabel.text = "점수 \(correctCount)"
        questionLabel.attributedText = questionText(for: word)
        answerField.text = ""
        answerField.isEnabled = true
        feedbackLabel.attributedText = nil
        feedbackLabel.text = ""
        isWaitingForNextQuestion = false
        checkButton.setTitle("정답 확인", for: .normal)
        dontKnowButton.isHidden = false
        updateProgressBar()
        if view.window != nil {
            answerField.becomeFirstResponder()
        }
    }

    @IBAction func checkAnswer() {
        if isWaitingForNextQuestion {
            showQuestion()
            return
        }

        guard let word = words.first else { return }
        let answer = HangulComposer.compose(answerField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        guard !answer.isEmpty else {
            feedbackLabel.text = "답을 먼저 입력하세요"
            answerField.becomeFirstResponder()
            return
        }

        if word.meaning.contains(answer) {
            words.removeFirst()
            correctCount += 1
            scoreLabel.text = "점수 \(correctCount)"
            showFeedback(result: "정답", for: word)
            WordStore.shared.mark(word, as: .memorized)
        } else {
            markCurrentWordForReview(word, result: "틀림")
        }

        updateProgressBar()
    }

    @IBAction func dontKnowAnswer() {
        guard !isWaitingForNextQuestion, let word = words.first else { return }
        markCurrentWordForReview(word, result: "모르겠음")
        updateProgressBar()
    }

    private func markCurrentWordForReview(_ word: Word, result: String) {
        words.removeFirst()
        reviewedTerms.insert(word.term)
        insertReviewWord(word)
        showFeedback(result: result, for: word)
        WordStore.shared.mark(word, as: .review)
    }

    private func showFeedback(result: String, for word: Word) {
        feedbackLabel.attributedText = feedbackText(result: result, for: word)
        answerField.isEnabled = false
        view.endEditing(true)
        isWaitingForNextQuestion = true
        checkButton.setTitle("다음 문제", for: .normal)
        dontKnowButton.isHidden = true
    }

    private func insertReviewWord(_ word: Word) {
        guard !words.isEmpty else {
            words.insert(word, at: 0)
            return
        }

        let index = Int.random(in: 1...words.count)
        words.insert(word, at: index)
    }

    private func questionText(for word: Word) -> NSAttributedString {
        let text = NSMutableAttributedString()
        let termStyle = NSMutableParagraphStyle()
        termStyle.alignment = .center
        termStyle.lineSpacing = 2

        text.append(NSAttributedString(
            string: word.term,
            attributes: [
                .font: UIFont.boldSystemFont(ofSize: 28),
                .foregroundColor: UIColor(red: 0.10, green: 0.31, blue: 0.52, alpha: 1),
                .paragraphStyle: termStyle
            ]
        ))

        guard !word.example.isEmpty else { return text }

        let exampleStyle = NSMutableParagraphStyle()
        exampleStyle.alignment = .center
        exampleStyle.lineSpacing = 3

        text.append(NSAttributedString(
            string: "\n\n예문: \(word.example)",
            attributes: [
                .font: UIFont.systemFont(ofSize: 16),
                .foregroundColor: UIColor.black,
                .paragraphStyle: exampleStyle
            ]
        ))
        return text
    }

    private func feedbackText(result: String, for word: Word) -> NSAttributedString {
        let text = NSMutableAttributedString()
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineSpacing = 6

        appendFeedbackLine("\(result)", to: text, font: .boldSystemFont(ofSize: 17), paragraph: paragraph)
        appendFeedbackLine("정답 : \(word.meaning)", to: text, font: .boldSystemFont(ofSize: 17), paragraph: paragraph)

        if !word.reading.isEmpty {
            appendFeedbackLine("발음 : [\(word.reading)]", to: text, font: .systemFont(ofSize: 16), paragraph: paragraph)
        }
        if !word.example.isEmpty {
            appendFeedbackLine("예문 : \(word.example)", to: text, font: .boldSystemFont(ofSize: 16), paragraph: paragraph)
        }
        if !word.exampleMeaning.isEmpty {
            appendFeedbackLine("예문해석 : \(word.exampleMeaning)", to: text, font: .systemFont(ofSize: 16), paragraph: paragraph)
        }

        return text
    }

    private func appendFeedbackLine(_ line: String, to text: NSMutableAttributedString, font: UIFont, paragraph: NSParagraphStyle) {
        if text.length > 0 {
            text.append(NSAttributedString(string: "\n"))
        }
        text.append(NSAttributedString(
            string: line,
            attributes: [
                .font: font,
                .foregroundColor: UIColor.darkText,
                .paragraphStyle: paragraph
            ]
        ))
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let result = segue.destination as? ResultViewController else { return }
        result.configure(
            totalCount: totalCount,
            memorizedCount: correctCount,
            reviewCount: reviewedTerms.count,
            screenTitle: "타이핑 학습 결과",
            messageText: "타이핑 학습 끝",
            percentText: "정답률",
            memorizedText: "맞음",
            reviewText: "틀림"
        )
    }

    private func showResultLater() {
        guard !didShowResult else { return }
        didShowResult = true
        if let bookID = bookID, let sessionIndex = sessionIndex {
            WordStore.shared.markSessionCompleted(bookID: bookID, index: sessionIndex)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.performSegue(withIdentifier: "showQuizResult", sender: nil)
        }
    }

    @objc private func normalizeAnswerText() {
        guard !isNormalizingAnswer else { return }
        let originalText = answerField.text ?? ""
        let composedText = HangulComposer.compose(originalText)
        guard originalText != composedText else { return }

        isNormalizingAnswer = true
        answerField.text = composedText
        isNormalizingAnswer = false
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func keyboardWillChangeFrame(_ notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let frameValue = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue
        else { return }

        let keyboardFrame = view.convert(frameValue.cgRectValue, from: nil)
        let baseBottomInset = max(0, view.safeAreaInsets.bottom - additionalSafeAreaInsets.bottom)
        let overlap = max(0, view.bounds.maxY - keyboardFrame.minY - baseBottomInset)
        animateKeyboardLayout(notification: notification, bottomInset: originalAdditionalSafeAreaInsets.bottom + max(0, overlap - 84))
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        animateKeyboardLayout(notification: notification, bottomInset: originalAdditionalSafeAreaInsets.bottom)
    }

    private func animateKeyboardLayout(notification: Notification, bottomInset: CGFloat) {
        let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25
        let curveRaw = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt ?? UIView.AnimationOptions.curveEaseInOut.rawValue
        let options = UIView.AnimationOptions(rawValue: curveRaw << 16)

        additionalSafeAreaInsets.bottom = bottomInset
        UIView.animate(withDuration: duration, delay: 0, options: options) {
            self.view.layoutIfNeeded()
        }
    }

    private func updateProgressBar() {
        let progress = totalCount == 0 ? 0 : CGFloat(correctCount) / CGFloat(totalCount)
        let imageSize = progressBarImageView.bounds.size == .zero
            ? CGSize(width: 320, height: 16)
            : progressBarImageView.bounds.size
        progressBarImageView.image = UIFactory.progressBarImage(progress: progress, size: imageSize)
    }
}

private enum HangulComposer {
    private static let initials: [Character: Int] = [
        "ㄱ": 0, "ㄲ": 1, "ㄴ": 2, "ㄷ": 3, "ㄸ": 4, "ㄹ": 5, "ㅁ": 6,
        "ㅂ": 7, "ㅃ": 8, "ㅅ": 9, "ㅆ": 10, "ㅇ": 11, "ㅈ": 12,
        "ㅉ": 13, "ㅊ": 14, "ㅋ": 15, "ㅌ": 16, "ㅍ": 17, "ㅎ": 18
    ]

    private static let vowels: [Character: Int] = [
        "ㅏ": 0, "ㅐ": 1, "ㅑ": 2, "ㅒ": 3, "ㅓ": 4, "ㅔ": 5, "ㅕ": 6,
        "ㅖ": 7, "ㅗ": 8, "ㅘ": 9, "ㅙ": 10, "ㅚ": 11, "ㅛ": 12,
        "ㅜ": 13, "ㅝ": 14, "ㅞ": 15, "ㅟ": 16, "ㅠ": 17, "ㅡ": 18,
        "ㅢ": 19, "ㅣ": 20
    ]

    private static let finals: [Character: Int] = [
        "ㄱ": 1, "ㄲ": 2, "ㄳ": 3, "ㄴ": 4, "ㄵ": 5, "ㄶ": 6,
        "ㄷ": 7, "ㄹ": 8, "ㄺ": 9, "ㄻ": 10, "ㄼ": 11, "ㄽ": 12,
        "ㄾ": 13, "ㄿ": 14, "ㅀ": 15, "ㅁ": 16, "ㅂ": 17, "ㅄ": 18,
        "ㅅ": 19, "ㅆ": 20, "ㅇ": 21, "ㅈ": 22, "ㅊ": 23, "ㅋ": 24,
        "ㅌ": 25, "ㅍ": 26, "ㅎ": 27
    ]

    static func compose(_ text: String) -> String {
        let characters = Array(text)
        var result = ""
        var index = 0

        while index < characters.count {
            let current = characters[index]
            guard
                let initialIndex = initials[current],
                index + 1 < characters.count,
                let vowelIndex = vowels[characters[index + 1]]
            else {
                result.append(current)
                index += 1
                continue
            }

            var finalIndex = 0
            var nextIndex = index + 2
            if
                index + 2 < characters.count,
                let possibleFinalIndex = finals[characters[index + 2]],
                !(index + 3 < characters.count && vowels[characters[index + 3]] != nil)
            {
                finalIndex = possibleFinalIndex
                nextIndex = index + 3
            }

            let scalarValue = 0xAC00 + ((initialIndex * 21) + vowelIndex) * 28 + finalIndex
            if let scalar = UnicodeScalar(scalarValue) {
                result.append(Character(scalar))
            }
            index = nextIndex
        }

        return result
    }
}

extension QuizViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        checkAnswer()
        return true
    }
}
