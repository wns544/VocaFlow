import UIKit

final class QuizViewController: UIViewController {
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet weak var answerField: UITextField!
    @IBOutlet weak var feedbackLabel: UILabel!

    private var words = Array(WordStore.shared.words.shuffled().prefix(10))
    private var currentIndex = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "퀴즈"
        showQuestion()
    }

    private func showQuestion() {
        guard currentIndex < words.count else {
            feedbackLabel.text = "퀴즈 끝"
            questionLabel.text = "-"
            answerField.text = ""
            return
        }

        let word = words[currentIndex]
        progressLabel.text = "문제 \(currentIndex + 1) / \(words.count)"
        questionLabel.text = word.term
        answerField.text = ""
        feedbackLabel.text = "뜻을 입력하고 확인"
    }

    @IBAction func checkAnswer() {
        guard currentIndex < words.count else { return }
        let word = words[currentIndex]
        let answer = (answerField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        if !answer.isEmpty && word.meaning.contains(answer) {
            feedbackLabel.text = "맞은듯\n\(word.meaning)"
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
}
