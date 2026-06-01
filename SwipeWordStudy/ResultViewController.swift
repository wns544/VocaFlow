import UIKit

final class ResultViewController: UIViewController {
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var totalLabel: UILabel!
    @IBOutlet weak var memorizedLabel: UILabel!
    @IBOutlet weak var reviewLabel: UILabel!

    private var totalCount = 0
    private var memorizedCount = 0
    private var reviewCount = 0

    func configure(totalCount: Int, memorizedCount: Int, reviewCount: Int) {
        self.totalCount = totalCount
        self.memorizedCount = memorizedCount
        self.reviewCount = reviewCount
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "학습 결과"
        navigationItem.hidesBackButton = true
        messageLabel.text = "오늘 학습 끝"
        totalLabel.text = "전체 \(totalCount)"
        memorizedLabel.text = "외움 \(memorizedCount)"
        reviewLabel.text = "다시 봄 \(reviewCount)"
    }

    @IBAction func goHome() {
        navigationController?.popToRootViewController(animated: true)
    }
}
