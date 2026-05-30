import UIKit

final class WordListViewController: UIViewController {
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!

    private var filteredWords = WordStore.shared.words

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "단어 목록"
        view.backgroundColor = UIFactory.backgroundColor
        UIFactory.applyNavigationStyle(to: navigationController)
        setupStoryboardParts()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        filterWords(with: searchBar.text ?? "")
    }

    private func setupStoryboardParts() {
        searchBar.placeholder = "단어 검색"
        searchBar.delegate = self
        searchBar.searchBarStyle = .minimal
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(WordListCell.self, forCellReuseIdentifier: "WordCell")
        tableView.backgroundColor = UIFactory.backgroundColor
        tableView.rowHeight = 78
    }

    private func filterWords(with text: String) {
        let query = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if query.isEmpty {
            filteredWords = WordStore.shared.words
        } else {
            filteredWords = WordStore.shared.words.filter {
                $0.term.lowercased().contains(query) || $0.meaning.lowercased().contains(query)
            }
        }
        tableView.reloadData()
    }
}

extension WordListViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filterWords(with: searchText)
    }
}

extension WordListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredWords.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let word = filteredWords[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "WordCell", for: indexPath) as? WordListCell
            ?? WordListCell(style: .subtitle, reuseIdentifier: "WordCell")
        cell.configure(with: word)
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let word = filteredWords[indexPath.row]
        let detail = storyboard?.instantiateViewController(withIdentifier: "WordDetailViewController") as? WordDetailViewController
            ?? WordDetailViewController()
        detail.configure(word: word)
        navigationController?.pushViewController(detail, animated: true)
    }
}

final class WordListCell: UITableViewCell {
    func configure(with word: Word) {
        textLabel?.text = word.term
        textLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        textLabel?.textColor = UIFactory.primaryColor

        detailTextLabel?.text = "\(word.meaning)  ·  \(word.state.rawValue)"
        detailTextLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        detailTextLabel?.textColor = UIFactory.mutedTextColor
    }
}
