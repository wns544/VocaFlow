import UIKit

final class WordListViewController: UIViewController {
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var filterControl: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableTopConstraint: NSLayoutConstraint!

    private let wordModeHeaderButton = UIButton(type: .system)

    private enum ViewMode {
        case sessions
        case words
    }

    private var wordBook: WordBook?
    private var filteredWords: [Word] = []
    private var viewMode: ViewMode = .sessions
    private var isCustomBook: Bool {
        guard let id = wordBook?.id else { return false }
        return id != "default"
    }

    func configure(wordBook: WordBook) {
        self.wordBook = wordBook
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        UIFactory.applyNavigationStyle(to: navigationController)
        setupStoryboardParts()
        updateModeUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshWordBook()
        filterWords()
        updateModeUI()
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.setEditing(editing, animated: animated)
    }

    private func setupStoryboardParts() {
        searchBar.placeholder = "단어 검색"
        searchBar.delegate = self
        searchBar.searchBarStyle = .minimal
        filterControl.selectedSegmentIndex = 0
        tableView.dataSource = self
        tableView.delegate = self
        setupWordModeHeaderButton()
    }

    private func setupWordModeHeaderButton() {
        wordModeHeaderButton.setTitle("단어목록", for: .normal)
        wordModeHeaderButton.setTitleColor(UIFactory.primaryColor, for: .normal)
        wordModeHeaderButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        wordModeHeaderButton.backgroundColor = .white
        wordModeHeaderButton.layer.cornerRadius = 12
        wordModeHeaderButton.layer.borderWidth = 1
        wordModeHeaderButton.layer.borderColor = UIColor(red: 0.82, green: 0.88, blue: 0.93, alpha: 1).cgColor
        wordModeHeaderButton.addTarget(self, action: #selector(showWordMode), for: .touchUpInside)
    }

    private func refreshWordBook() {
        guard let id = wordBook?.id else { return }
        wordBook = WordStore.shared.wordBook(id: id)
    }

    private func filterWords() {
        let query = (searchBar.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let sourceWords = wordBook?.words ?? WordStore.shared.words
        filteredWords = sourceWords.filter { word in
            let matchesSearch = query.isEmpty
                || word.term.lowercased().contains(query)
                || word.meaning.lowercased().contains(query)
            let matchesState: Bool
            switch filterControl.selectedSegmentIndex {
            case 1:
                matchesState = word.state == .memorized
            case 2:
                matchesState = word.state == .review
            default:
                matchesState = true
            }
            return matchesSearch && matchesState
        }
        if viewMode == .words {
            title = "\(wordBook?.name ?? "단어 목록") (\(filteredWords.count))"
        }
        tableView.reloadData()
    }

    private func updateModeUI() {
        switch viewMode {
        case .sessions:
            title = wordBook?.name ?? "세션"
            searchBar.isHidden = true
            filterControl.isHidden = true
            tableTopConstraint.constant = -96
            let resetButton = UIBarButtonItem(title: "초기화", style: .plain, target: self, action: #selector(resetSessionsFromButton))
            navigationItem.rightBarButtonItem = resetButton
            tableView.tableHeaderView = makeWordModeHeaderView()
        case .words:
            searchBar.isHidden = false
            filterControl.isHidden = false
            tableTopConstraint.constant = 8
            tableView.tableHeaderView = nil
            let sessionButton = UIBarButtonItem(title: "세션", style: .plain, target: self, action: #selector(showSessionMode))
            if isCustomBook {
                navigationItem.rightBarButtonItems = [editButtonItem, sessionButton]
            } else {
                navigationItem.rightBarButtonItem = sessionButton
            }
        }
        tableView.reloadData()
    }

    private func makeWordModeHeaderView() -> UIView {
        let header = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 64))
        let buttonWidth = min(max(tableView.bounds.width * 0.62, 180), 260)
        wordModeHeaderButton.frame = CGRect(
            x: (tableView.bounds.width - buttonWidth) / 2,
            y: 10,
            width: buttonWidth,
            height: 44
        )
        header.addSubview(wordModeHeaderButton)
        return header
    }

    @objc private func showWordMode() {
        viewMode = .words
        filterWords()
        updateModeUI()
    }

    @objc private func showSessionMode() {
        viewMode = .sessions
        updateModeUI()
    }

    private func editWord(_ word: Word) {
        guard let bookID = wordBook?.id, isCustomBook else {
            showMessage(title: "기본 단어", message: "기본 단어장은 그대로 두었어요.")
            return
        }

        let alert = UIAlertController(title: "단어 수정", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = word.term
            textField.placeholder = "단어"
        }
        alert.addTextField { textField in
            textField.text = word.meaning
            textField.placeholder = "뜻"
        }
        alert.addTextField { textField in
            textField.text = word.reading
            textField.placeholder = "발음"
        }
        alert.addTextField { textField in
            textField.text = word.example
            textField.placeholder = "예문"
        }
        alert.addTextField { textField in
            textField.text = word.exampleMeaning
            textField.placeholder = "예문뜻"
        }
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "저장", style: .default) { _ in
            let fields = alert.textFields ?? []
            let term = fields[safe: 0]?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let meaning = fields[safe: 1]?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let reading = fields[safe: 2]?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let example = fields[safe: 3]?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let exampleMeaning = fields[safe: 4]?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            guard !term.isEmpty, !meaning.isEmpty, !reading.isEmpty else { return }
            let newWord = Word(
                term: term,
                meaning: meaning,
                reading: reading,
                example: example,
                exampleMeaning: exampleMeaning,
                state: word.state
            )
            WordStore.shared.updateWord(word, inBook: bookID, with: newWord)
            self.refreshWordBook()
            self.filterWords()
        })
        present(alert, animated: true)
    }

    private func showMessage(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

    @objc private func resetSessionsFromButton() {
        refreshWordBook()
        guard let book = wordBook else { return }
        showResetSessionMenu(book: book)
    }

    private func startSession(book: WordBook, index: Int) {
        let words = WordStore.shared.wordsForSession(book: book, index: index)
        guard !words.isEmpty else { return }

        let session = StudySession(words: words, bookID: book.id, sessionIndex: index)
        let studyViewController = storyboard?.instantiateViewController(withIdentifier: "StudyViewController") as? StudyViewController
            ?? StudyViewController(session: session)
        studyViewController.configure(session: session)
        studyViewController.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(studyViewController, animated: true)
    }

    private func showResetSessionMenu(book: WordBook) {
        let alert = UIAlertController(title: "기록 초기화", message: "완료 표시만 지워지고 단어는 삭제되지 않아요.", preferredStyle: .actionSheet)
        let count = WordStore.shared.sessionCount(for: book)

        alert.addAction(UIAlertAction(title: "이 단어장 전체", style: .destructive) { _ in
            WordStore.shared.resetSessionHistory(bookID: book.id)
            self.filterWords()
            self.updateModeUI()
        })

        for index in 0..<count where WordStore.shared.isSessionCompleted(bookID: book.id, index: index) {
            alert.addAction(UIAlertAction(title: "\(index + 1)세션 기록 지우기", style: .default) { _ in
                WordStore.shared.resetSessionHistory(bookID: book.id, index: index)
                self.filterWords()
                self.updateModeUI()
            })
        }

        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        present(alert, animated: true)
    }

    @IBAction func stateFilterChanged() {
        filterWords()
    }
}

extension WordListViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filterWords()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

extension WordListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch viewMode {
        case .sessions:
            guard let book = wordBook else { return 0 }
            return WordStore.shared.sessionCount(for: book)
        case .words:
            return filteredWords.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "WordCell", for: indexPath)
        switch viewMode {
        case .sessions:
            guard let book = wordBook else { return cell }
            let words = WordStore.shared.wordsForSession(book: book, index: indexPath.row)
            let isDone = WordStore.shared.isSessionCompleted(bookID: book.id, index: indexPath.row)
            cell.textLabel?.text = "\(indexPath.row + 1)세션"
            cell.detailTextLabel?.text = "\(isDone ? "학습함" : "아직 안함")  ·  \(words.count)개 단어"
            cell.accessoryType = .disclosureIndicator
        case .words:
            let word = filteredWords[indexPath.row]
            cell.textLabel?.text = word.term
            cell.detailTextLabel?.text = "\(word.meaning)  ·  \(word.state.rawValue)"
            cell.accessoryType = .disclosureIndicator
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if viewMode == .sessions {
            guard let book = wordBook else { return }
            startSession(book: book, index: indexPath.row)
            return
        }

        let word = filteredWords[indexPath.row]
        let detail = storyboard?.instantiateViewController(withIdentifier: "WordDetailViewController") as? WordDetailViewController
            ?? WordDetailViewController()
        detail.configure(word: word)
        navigationController?.pushViewController(detail, animated: true)
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        viewMode == .words && isCustomBook
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard viewMode == .words else { return nil }
        guard let bookID = wordBook?.id, isCustomBook else { return nil }
        let word = filteredWords[indexPath.row]
        let delete = UIContextualAction(style: .destructive, title: "삭제") { _, _, completion in
            WordStore.shared.deleteWord(word, inBook: bookID)
            self.refreshWordBook()
            self.filterWords()
            completion(true)
        }
        return UISwipeActionsConfiguration(actions: [delete])
    }

    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard viewMode == .words else { return nil }
        guard isCustomBook else { return nil }
        let word = filteredWords[indexPath.row]
        let edit = UIContextualAction(style: .normal, title: "수정") { _, _, completion in
            self.editWord(word)
            completion(true)
        }
        edit.backgroundColor = UIFactory.secondaryColor
        return UISwipeActionsConfiguration(actions: [edit])
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
