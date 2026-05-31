import UIKit

final class QuizViewController: UIViewController {
    @IBOutlet weak var messageLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "퀴즈"
        messageLabel.text = "퀴즈 화면은 아직 만드는 중"
    }
}
