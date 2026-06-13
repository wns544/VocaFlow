import UIKit
import MobileCoreServices

final class WordBookListViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addButton: UIButton!

    private var books: [WordBook] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "단어장"
        UIFactory.applyNavigationStyle(to: navigationController)
        navigationItem.rightBarButtonItem = editButtonItem
        addButton.layer.cornerRadius = 22
        addButton.layer.shadowColor = UIColor.black.cgColor
        addButton.layer.shadowOpacity = 0.08
        addButton.layer.shadowRadius = 10
        addButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        tableView.dataSource = self
        tableView.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        books = WordStore.shared.books
        tableView.reloadData()
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.setEditing(editing, animated: animated)
    }

    private func renameBook(_ book: WordBook) {
        guard book.id != "default" else {
            showMessage(title: "기본 단어장", message: "기본 단어장은 이름을 바꾸지 않았어요.")
            return
        }

        let alert = UIAlertController(title: "단어장 이름", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = book.name
            textField.placeholder = "단어장 이름"
        }
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "저장", style: .default) { _ in
            let name = alert.textFields?.first?.text ?? ""
            WordStore.shared.renameBook(id: book.id, name: name)
            self.books = WordStore.shared.books
            self.tableView.reloadData()
        })
        present(alert, animated: true)
    }

    private func setQuickStudyBook(_ book: WordBook) {
        WordStore.shared.setQuickStudyBook(id: book.id)
        books = WordStore.shared.books
        tableView.reloadData()
        showMessage(title: "쇼츠 학습 설정", message: "\(book.name) 단어장을 쇼츠 학습에 연결했어요.")
    }

    private func showMessage(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

    @objc private func importCSV() {
        let picker = UIDocumentPickerViewController(documentTypes: ["public.comma-separated-values-text", kUTTypePlainText as String], in: .import)
        picker.delegate = self
        picker.allowsMultipleSelection = false
        present(picker, animated: true)
    }

    private func handleImportedCSV(url: URL) {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else {
            showMessage(title: "가져오기 실패", message: "CSV 파일을 읽을 수 없어요.")
            return
        }

        let words = CSVWordParser.words(from: content)
        guard !words.isEmpty else {
            showMessage(title: "가져오기 실패", message: "단어,뜻,발음,예문 형식의 데이터가 필요해요.")
            return
        }

        let fileName = url.deletingPathExtension().lastPathComponent
        WordStore.shared.addCustomBook(name: fileName, words: words)
        books = WordStore.shared.books
        tableView.reloadData()
        showMessage(title: "추가 완료", message: "\(fileName) 단어장에 \(words.count)개 단어를 추가했어요.")
    }
}

extension WordBookListViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        handleImportedCSV(url: url)
    }
}

extension WordBookListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        books.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let book = books[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "WordBookCell", for: indexPath)
        let totalSessions = WordStore.shared.sessionCount(for: book)
        let completedSessions = WordStore.shared.completedSessionCount(for: book.id)
        let quickText = WordStore.shared.quickStudyBook.id == book.id ? "  ·  쇼츠 학습" : ""
        cell.textLabel?.text = book.name
        cell.detailTextLabel?.text = "\(book.words.count)개 단어  ·  세션 \(completedSessions)/\(totalSessions)\(quickText)"
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        books[indexPath.row].id == "default" ? .none : .delete
    }

    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        books[indexPath.row].id != "default"
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        books[indexPath.row].id != "default"
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        let book = books[indexPath.row]
        guard book.id != "default" else { return }

        WordStore.shared.deleteBook(id: book.id)
        books = WordStore.shared.books
        tableView.deleteRows(at: [indexPath], with: .automatic)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let book = books[indexPath.row]
        let listViewController = storyboard?.instantiateViewController(withIdentifier: "WordListViewController") as? WordListViewController
            ?? WordListViewController()
        listViewController.configure(wordBook: book)
        navigationController?.pushViewController(listViewController, animated: true)
    }

    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        books[indexPath.row].id != "default"
    }

    func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        proposedDestinationIndexPath.row == 0
            ? IndexPath(row: 1, section: proposedDestinationIndexPath.section)
            : proposedDestinationIndexPath
    }

    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let source = sourceIndexPath.row - 1
        let destination = max(0, destinationIndexPath.row - 1)
        WordStore.shared.moveCustomBook(from: source, to: destination)
        books = WordStore.shared.books
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let book = books[indexPath.row]
        guard book.id != "default" else { return nil }

        let delete = UIContextualAction(style: .destructive, title: "삭제") { _, _, completion in
            WordStore.shared.deleteBook(id: book.id)
            self.books = WordStore.shared.books
            tableView.deleteRows(at: [indexPath], with: .automatic)
            completion(true)
        }
        return UISwipeActionsConfiguration(actions: [delete])
    }

    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let book = books[indexPath.row]
        let quick = UIContextualAction(style: .normal, title: "쇼츠") { _, _, completion in
            self.setQuickStudyBook(book)
            completion(true)
        }
        quick.backgroundColor = UIFactory.primaryColor

        guard book.id != "default" else {
            return UISwipeActionsConfiguration(actions: [quick])
        }
        let rename = UIContextualAction(style: .normal, title: "이름") { _, _, completion in
            self.renameBook(book)
            completion(true)
        }
        rename.backgroundColor = UIFactory.secondaryColor
        return UISwipeActionsConfiguration(actions: [rename, quick])
    }
}
