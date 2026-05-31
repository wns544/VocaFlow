import UIKit

final class WordListViewController: UIViewController {
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!

    private var filteredWords = WordStore.shared.words

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "단어 목록"
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "WordCell", for: indexPath)
        cell.textLabel?.text = word.term
        cell.detailTextLabel?.text = "\(word.meaning)  ·  \(word.state.rawValue)"
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
