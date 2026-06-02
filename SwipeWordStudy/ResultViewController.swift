import UIKit

final class ResultViewController: UIViewController {
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var totalLabel: UILabel!
    @IBOutlet weak var memorizedLabel: UILabel!
    @IBOutlet weak var reviewLabel: UILabel!

    private var totalCount = 0
    private var memorizedCount = 0
    private var reviewCount = 0
    private var screenTitle = "학습 결과"
    private var messageText = "오늘 학습 끝"
    private var memorizedText = "외움"
    private var reviewText = "다시 봄"

    func configure(
        totalCount: Int,
        memorizedCount: Int,
        reviewCount: Int,
        screenTitle: String = "학습 결과",
        messageText: String = "오늘 학습 끝",
        memorizedText: String = "외움",
        reviewText: String = "다시 봄"
    ) {
        self.totalCount = totalCount
        self.memorizedCount = memorizedCount
        self.reviewCount = reviewCount
        self.screenTitle = screenTitle
        self.messageText = messageText
        self.memorizedText = memorizedText
        self.reviewText = reviewText
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = screenTitle
        navigationItem.hidesBackButton = true
        messageLabel.text = messageText
        totalLabel.text = "전체 \(totalCount)"
        memorizedLabel.text = "\(memorizedText) \(memorizedCount)"
        reviewLabel.text = "\(reviewText) \(reviewCount)"
    }

    @IBAction func goHome() {
        navigationController?.popToRootViewController(animated: true)
    }
}
