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
        view.backgroundColor = UIFactory.backgroundColor
        UIFactory.applyNavigationStyle(to: navigationController)
        setupStoryboardView()
        setupButtons()
    }

    private func setupStoryboardView() {
        titleLabel?.text = "VocaFlow"
        titleLabel?.font = UIFont.systemFont(ofSize: 34, weight: .bold)
        titleLabel?.textColor = UIFactory.primaryColor

        subtitleLabel?.text = "단어 카드를 넘기면서 외우는 앱"
        subtitleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        subtitleLabel?.textColor = UIFactory.mutedTextColor
        subtitleLabel?.numberOfLines = 0

        startButton?.setTitle("학습 시작", for: .normal)
        listButton?.setTitle("단어 목록", for: .normal)

        // 퀴즈는 아직 화면만 대충 남겨둠
        quizButton?.isHidden = true
    }

    private func setupButtons() {
        [startButton, listButton].forEach {
            $0?.layer.cornerRadius = 14
            $0?.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        }

        startButton?.backgroundColor = UIFactory.secondaryColor
        startButton?.setTitleColor(.white, for: .normal)
        listButton?.backgroundColor = UIFactory.cardColor
        listButton?.setTitleColor(UIFactory.primaryColor, for: .normal)
        listButton?.layer.borderWidth = 1
        listButton?.layer.borderColor = UIFactory.lineColor.cgColor
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
