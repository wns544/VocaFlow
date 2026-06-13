import UIKit

final class SettingsViewController: UIViewController {
    @IBOutlet weak var settingsStackView: UIStackView!
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var stepper: UIStepper!
    @IBOutlet weak var helperLabel: UILabel!
    @IBOutlet weak var statsLabel: UILabel!
    @IBOutlet weak var dDaySwitch: UISwitch!
    @IBOutlet weak var targetDateLabel: UILabel!
    @IBOutlet weak var targetDateButton: UIButton!
    @IBOutlet weak var targetNameLabel: UILabel!
    @IBOutlet weak var targetNameButton: UIButton!
    @IBOutlet weak var csvExampleButton: UIButton!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var appInfoLabel: UILabel!
    private var sectionBackgroundViews: [UIView] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "설정"
        UIFactory.applyNavigationStyle(to: navigationController)
        setupStoryboardParts()
        updateCountLabel()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateSectionBackgrounds()
    }

    private func setupStoryboardParts() {
        stepper.minimumValue = 5
        stepper.maximumValue = 100
        stepper.stepValue = 5
        stepper.value = Double(WordStore.shared.sessionWordCount)
        dDaySwitch.isOn = WordStore.shared.isDdayEnabled
        styleSettingButton(targetDateButton)
        styleSettingButton(targetNameButton)
        styleSettingButton(csvExampleButton)
        styleSettingButton(resetButton)
        appInfoLabel.layer.cornerRadius = 10
        appInfoLabel.layer.borderWidth = 0
        appInfoLabel.layer.masksToBounds = true
        targetDateLabel.textAlignment = .left
        targetNameLabel.textAlignment = .left
        helperLabel.textAlignment = .left
        statsLabel.textAlignment = .left
        helperLabel.text = "CSV 형식: 단어 / 뜻 / 발음 / 예문 / 예문뜻"
        appInfoLabel.text = """
        VocaFlow
        쇼츠 학습과 타이핑 학습으로 단어를 복습하는 앱

        기본 단어장: first20hours/google-10000-english 공개 빈출단어 목록 참고
        뜻/발음/예문은 앱 학습용으로 정리
        """
        applySectionSpacing()
        makeSectionBackgrounds()
    }

    private func styleSettingButton(_ button: UIButton) {
        button.layer.cornerRadius = 10
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor(red: 0.86, green: 0.91, blue: 0.95, alpha: 1).cgColor
        button.backgroundColor = .white
    }

    private func makeSectionBackgrounds() {
        sectionBackgroundViews.forEach { $0.removeFromSuperview() }
        sectionBackgroundViews = (0..<5).map { _ in
            let view = UIView()
            view.backgroundColor = .white
            view.layer.cornerRadius = 14
            view.layer.borderWidth = 1
            view.layer.borderColor = UIColor(red: 0.82, green: 0.88, blue: 0.93, alpha: 1).cgColor
            view.layer.masksToBounds = true
            settingsStackView.insertSubview(view, at: 0)
            return view
        }
    }

    private func applySectionSpacing() {
        let arrangedViews = settingsStackView.arrangedSubviews
        for index in [1, 7, 11, 13] where arrangedViews.indices.contains(index) {
            settingsStackView.setCustomSpacing(28, after: arrangedViews[index])
        }
    }

    private func updateSectionBackgrounds() {
        guard sectionBackgroundViews.count == 5 else { return }
        let arrangedViews = settingsStackView.arrangedSubviews
        guard arrangedViews.count >= 16 else { return }

        let groups = [
            Array(arrangedViews[0...1]),
            Array(arrangedViews[2...7]),
            Array(arrangedViews[8...11]),
            Array(arrangedViews[12...13]),
            Array(arrangedViews[14...15])
        ]

        for (index, views) in groups.enumerated() {
            sectionBackgroundViews[index].frame = sectionFrame(containing: views)
        }
    }

    private func sectionFrame(containing views: [UIView]) -> CGRect {
        let unionFrame = views.reduce(CGRect.null) { result, view in
            result.union(view.frame)
        }
        return unionFrame.insetBy(dx: -16, dy: -8)
    }

    private func updateCountLabel() {
        let count = WordStore.shared.sessionWordCount
        countLabel.text = "세션 단어 수: \(count)개"
        statsLabel.text = "총 단어장 \(WordStore.shared.books.count)개  ·  총 단어 \(WordStore.shared.words.count)개"
        dDaySwitch.isOn = WordStore.shared.isDdayEnabled
        targetNameLabel.text = "D-day 이름: \(WordStore.shared.targetNameDescription)"
        targetDateLabel.text = "목표일: \(WordStore.shared.targetDateDescription)"
    }

    @IBAction func sessionCountChanged() {
        WordStore.shared.sessionWordCount = Int(stepper.value)
        stepper.value = Double(WordStore.shared.sessionWordCount)
        updateCountLabel()
    }

    @IBAction func dDaySwitchChanged() {
        WordStore.shared.isDdayEnabled = dDaySwitch.isOn
        updateCountLabel()
    }

    @IBAction func setTargetDate() {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .wheels
        picker.date = WordStore.shared.targetDate ?? Date()
        picker.translatesAutoresizingMaskIntoConstraints = false

        let alert = UIAlertController(title: "D-day 날짜", message: "\n\n\n\n\n\n\n\n\n", preferredStyle: .alert)
        alert.view.addSubview(picker)
        NSLayoutConstraint.activate([
            picker.centerXAnchor.constraint(equalTo: alert.view.centerXAnchor),
            picker.topAnchor.constraint(equalTo: alert.view.topAnchor, constant: 58),
            picker.widthAnchor.constraint(equalToConstant: 270),
            picker.heightAnchor.constraint(equalToConstant: 180)
        ])
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "저장", style: .default) { _ in
            WordStore.shared.targetDate = picker.date
            self.updateCountLabel()
        })
        present(alert, animated: true)
    }

    @IBAction func setTargetName() {
        let alert = UIAlertController(title: "D-day 이름", message: "시험이나 목표의 이름을 적어 주세요.", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "예: 기말고사"
            textField.text = WordStore.shared.targetName
        }
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "저장", style: .default) { _ in
            let input = alert.textFields?.first?.text ?? ""
            WordStore.shared.targetName = input
            self.updateCountLabel()
        })
        present(alert, animated: true)
    }

    @IBAction func showCSVExample() {
        let message = """
        CSV는 엑셀이나 Numbers에서 만들 수 있어요.

        아래 순서로 적으면 됩니다.

        단어 / 뜻 / 발음 / 예문 / 예문뜻

        1열 단어, 2열 뜻, 3열 발음은 꼭 넣어야 합니다.
        4열 예문과 5열 예문뜻은 없어도 추가할 수 있습니다.

        예:
        apple,사과,ˈæp.əl,I eat an apple.,나는 사과를 먹는다.
        study,공부하다,ˈstʌd.i,,

        첫 줄에 제목을 넣어도 앱에서 알아서 건너뜁니다.
        CSV 파일 추가는 단어장 탭의 + 버튼에서 할 수 있어요.
        """
        showMessage(title: "CSV 삽입형식 안내", message: message)
    }

    @IBAction func resetStudyHistory() {
        let alert = UIAlertController(title: "학습 기록 초기화", message: "외움/다시 보기 상태를 처음 상태로 돌릴까요?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "초기화", style: .destructive) { _ in
            WordStore.shared.resetStudyStates()
            self.updateCountLabel()
            self.showMessage(title: "초기화 완료", message: "학습 상태를 새 단어로 되돌렸어요.")
        })
        present(alert, animated: true)
    }

    private func showMessage(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

enum CSVWordParser {
    static func words(from content: String) -> [Word] {
        content
            .components(separatedBy: .newlines)
            .compactMap { line in
                let columns = parseLine(line)
                guard columns.count >= 3 else { return nil }

                let term = columns[0].trimmingCharacters(in: .whitespacesAndNewlines)
                let meaning = columns[1].trimmingCharacters(in: .whitespacesAndNewlines)
                let reading = columns[2].trimmingCharacters(in: .whitespacesAndNewlines)
                let example = columns.count > 3 ? columns[3].trimmingCharacters(in: .whitespacesAndNewlines) : ""
                let exampleMeaning = columns.count > 4 ? columns[4].trimmingCharacters(in: .whitespacesAndNewlines) : ""
                let lowercasedTerm = term.lowercased()

                guard !["term", "word", "단어"].contains(lowercasedTerm) else { return nil }
                guard !term.isEmpty, !meaning.isEmpty, !reading.isEmpty else { return nil }
                return Word(
                    term: term,
                    meaning: meaning,
                    reading: reading,
                    example: example,
                    exampleMeaning: exampleMeaning,
                    state: .new
                )
            }
    }

    private static func parseLine(_ line: String) -> [String] {
        var columns: [String] = []
        var current = ""
        var isInsideQuote = false

        for character in line {
            if character == "\"" {
                isInsideQuote.toggle()
            } else if character == "," && !isInsideQuote {
                columns.append(current)
                current = ""
            } else {
                current.append(character)
            }
        }

        columns.append(current)
        return columns
    }
}
