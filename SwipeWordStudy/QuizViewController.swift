import UIKit

final class QuizViewController: UIViewController {
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet weak var answerField: UITextField!
    @IBOutlet weak var feedbackLabel: UILabel!

    private var words = Array(WordStore.shared.words.shuffled().prefix(10))
    private var currentIndex = 0
    private var correctCount = 0
    private var didShowResult = false

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "퀴즈"
        answerField.delegate = self
        showQuestion()
    }

    private func showQuestion() {
        guard currentIndex < words.count else {
            progressLabel.text = "문제 끝"
            scoreLabel.text = "점수 \(correctCount) / \(words.count)"
            feedbackLabel.text = "퀴즈 끝"
            questionLabel.text = "-"
            answerField.text = ""
            showResultLater()
            return
        }

        let word = words[currentIndex]
        progressLabel.text = "문제 \(currentIndex + 1) / \(words.count)"
        scoreLabel.text = "점수 \(correctCount)"
        questionLabel.text = word.term
        answerField.text = ""
        feedbackLabel.text = "뜻을 입력하고 확인"
    }

    @IBAction func checkAnswer() {
        guard currentIndex < words.count else { return }
        let word = words[currentIndex]
        let answer = (answerField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        guard !answer.isEmpty else {
            feedbackLabel.text = "뜻을 먼저 입력"
            answerField.becomeFirstResponder()
            return
        }

        answerField.resignFirstResponder()
        if word.meaning.contains(answer) {
            correctCount += 1
            scoreLabel.text = "점수 \(correctCount)"
            feedbackLabel.text = "맞음\n\(word.meaning)"
            WordStore.shared.mark(word, as: .memorized)
        } else {
            feedbackLabel.text = "틀림\n정답: \(word.meaning)"
            WordStore.shared.mark(word, as: .review)
        }

        currentIndex += 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            self.showQuestion()
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let result = segue.destination as? ResultViewController else { return }
        result.configure(
            totalCount: words.count,
            memorizedCount: correctCount,
            reviewCount: words.count - correctCount,
            screenTitle: "퀴즈 결과",
            messageText: "퀴즈 끝",
            percentText: "정답률",
            memorizedText: "맞음",
            reviewText: "틀림"
        )
    }

    private func showResultLater() {
        guard !didShowResult else { return }
        didShowResult = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.performSegue(withIdentifier: "showQuizResult", sender: nil)
        }
    }
}

extension QuizViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        checkAnswer()
        return true
    }
}
