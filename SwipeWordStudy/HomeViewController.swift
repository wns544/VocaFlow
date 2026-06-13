import UIKit

final class HomeViewController: UIViewController {
    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var subtitleLabel: UILabel?
    @IBOutlet weak var dDayStackView: UIStackView?
    @IBOutlet weak var dDayNameLabel: UILabel?
    @IBOutlet weak var dDayValueLabel: UILabel?
    @IBOutlet weak var streakLabel: UILabel?
    @IBOutlet weak var startButton: UIButton?
    @IBOutlet weak var listButton: UIButton?
    @IBOutlet weak var quizButton: UIButton?
    @IBOutlet weak var quickBookButton: UIButton?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "VocaFlow"
        listButton?.isHidden = true
        UIFactory.applyNavigationStyle(to: navigationController)
        quickBookButton?.setTitleColor(UIFactory.primaryColor, for: .normal)
        updateQuickStudyText()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateQuickStudyText()
    }

    private func updateQuickStudyText() {
        let book = WordStore.shared.quickStudyBook
        let nextIndex = WordStore.shared.nextIncompleteSessionIndex(for: book) + 1
        let showDday = WordStore.shared.shouldShowDday
        subtitleLabel?.text = "\(book.name) \(nextIndex)세션으로 바로 학습"
        quickBookButton?.setTitle("쇼츠 학습 단어장 지정", for: .normal)
        dDayStackView?.isHidden = !showDday
        dDayNameLabel?.text = WordStore.shared.targetNameDescription
        dDayValueLabel?.text = WordStore.shared.dDayText
        streakLabel?.text = "연속 학습 \(WordStore.shared.streakCount)일"
    }

    @IBAction func startStudy() {
        let quickSession = WordStore.shared.nextQuickStudySession()
        let session = StudySession(
            words: quickSession.words,
            bookID: quickSession.book.id,
            sessionIndex: quickSession.index
        )
        let studyViewController = storyboard?.instantiateViewController(withIdentifier: "StudyViewController") as? StudyViewController
            ?? StudyViewController(session: session)
        studyViewController.configure(session: session)
        studyViewController.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(studyViewController, animated: true)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let quizViewController = segue.destination as? QuizViewController else { return }
        quizViewController.hidesBottomBarWhenPushed = true
        let quickSession = WordStore.shared.nextQuickStudySession()
        quizViewController.configure(
            words: quickSession.words,
            bookID: quickSession.book.id,
            sessionIndex: quickSession.index
        )
    }

    @IBAction func showWordList() {
        let listViewController = storyboard?.instantiateViewController(withIdentifier: "WordListViewController") as? WordListViewController
            ?? WordListViewController()
        navigationController?.pushViewController(listViewController, animated: true)
    }

    @IBAction func chooseQuickStudyBook() {
        let currentBook = WordStore.shared.quickStudyBook
        let alert = UIAlertController(
            title: "쇼츠 학습 단어장",
            message: "쇼츠 학습과 타이핑 학습에서 사용할 단어장을 고르세요.",
            preferredStyle: .actionSheet
        )

        for book in WordStore.shared.books {
            let title = book.id == currentBook.id ? "\(book.name) ✓" : book.name
            alert.addAction(UIAlertAction(title: title, style: .default) { _ in
                WordStore.shared.setQuickStudyBook(id: book.id)
                self.updateQuickStudyText()
            })
        }

        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        present(alert, animated: true)
    }
}
