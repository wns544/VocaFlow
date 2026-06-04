import UIKit

final class HomeViewController: UIViewController {
    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var subtitleLabel: UILabel?
    @IBOutlet weak var startButton: UIButton?
    @IBOutlet weak var listButton: UIButton?
    @IBOutlet weak var quizButton: UIButton?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "홈"
        subtitleLabel?.text = "카드 학습과 퀴즈로 단어를 복습하세요"
        UIFactory.applyNavigationStyle(to: navigationController)
    }

    @IBAction func startStudy() {
        WordStore.shared.resetStudyStates()
        let session = StudySession(words: WordStore.shared.words)
        let studyViewController = storyboard?.instantiateViewController(withIdentifier: "StudyViewController") as? StudyViewController
            ?? StudyViewController(session: session)
        studyViewController.configure(session: session)
        navigationController?.pushViewController(studyViewController, animated: true)
    }

    @IBAction func showWordList() {
        let listViewController = storyboard?.instantiateViewController(withIdentifier: "WordListViewController") as? WordListViewController
            ?? WordListViewController()
        navigationController?.pushViewController(listViewController, animated: true)
    }
}
