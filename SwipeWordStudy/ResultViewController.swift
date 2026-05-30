import UIKit

final class ResultViewController: UIViewController {
    @IBOutlet weak var messageLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "학습 결과"
        view.backgroundColor = UIFactory.backgroundColor
        messageLabel.text = "결과 화면은 나중에 추가"
    }
}
